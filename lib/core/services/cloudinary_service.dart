import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

/// Uploads images with a server-generated Cloudinary signature. The API secret
/// is held by the Cloud Function and is never included in the mobile app.
class CloudinaryService {
  const CloudinaryService();

  static const int _maxFileBytes = 10 * 1024 * 1024;
  static const String _signedUploadPreset = 'velora_mobile_signed';

  Future<String> uploadImage({
    required File file,
    required String folder,
    required String publicId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in before uploading an image.');

    final fileSize = await file.length();
    if (fileSize == 0 || fileSize > _maxFileBytes) {
      throw StateError('Image must be smaller than 10 MB.');
    }

    final isProfileUpload =
        folder == 'profile_images' && publicId == 'profile_${user.uid}';
    final requestBody = <String, Object>{};
    if (isProfileUpload) {
      requestBody['profile'] = true;
    } else if (folder.startsWith('chat_images/')) {
      final roomId = folder.substring('chat_images/'.length);
      if (roomId.isEmpty || roomId.contains('/')) {
        throw ArgumentError('Invalid chat room upload path.');
      }
      requestBody.addAll({'roomId': roomId, 'messageId': publicId});
    } else {
      throw ArgumentError('Unsupported image upload path.');
    }

    final projectId = Firebase.app().options.projectId;
    if (projectId.isEmpty) {
      throw StateError('Firebase project is not configured.');
    }
    final signatureUrl = Uri.https(
      'us-central1-$projectId.cloudfunctions.net',
      '/createCloudinaryUploadSignature',
    );
    final idToken = await user.getIdToken();
    final appCheckToken = await FirebaseAppCheck.instance.getToken();
    if (appCheckToken == null) {
      throw StateError('Unable to verify this app for image upload.');
    }
    final signatureResponse = await http
        .post(
          signatureUrl,
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer $idToken',
            HttpHeaders.contentTypeHeader: 'application/json',
            'X-Firebase-AppCheck': appCheckToken,
          },
          body: jsonEncode(requestBody),
        )
        .timeout(const Duration(seconds: 20));
    if (signatureResponse.statusCode != 200) {
      throw StateError('Image upload authorization failed.');
    }

    final signatureData =
        jsonDecode(signatureResponse.body) as Map<String, dynamic>;
    final cloudName = signatureData['cloudName'] as String?;
    final apiKey = signatureData['apiKey'] as String?;
    final signedFolder = signatureData['folder'] as String?;
    final signedPublicId = signatureData['publicId'] as String?;
    final timestamp = signatureData['timestamp'];
    final signature = signatureData['signature'] as String?;
    if (cloudName == null ||
        !RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(cloudName) ||
        apiKey == null ||
        signedFolder != folder ||
        (!isProfileUpload && signedPublicId != publicId) ||
        (isProfileUpload &&
            !RegExp(
              '^profile_${RegExp.escape(user.uid)}_[0-9a-f-]{36}\$',
            ).hasMatch(signedPublicId ?? '')) ||
        timestamp is! int ||
        signature == null ||
        !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(signature)) {
      throw StateError('Invalid image upload authorization response.');
    }

    final uploadUrl = Uri.https(
      'api.cloudinary.com',
      '/v1_1/$cloudName/image/upload',
    );
    final uploadRequest = http.MultipartRequest('POST', uploadUrl)
      ..fields['api_key'] = apiKey
      ..fields['folder'] = signedFolder!
      ..fields['public_id'] = signedPublicId!
      ..fields['timestamp'] = timestamp.toString()
      ..fields['signature'] = signature
      ..fields['upload_preset'] = _signedUploadPreset
      ..fields['overwrite'] = 'false'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await uploadRequest.send().timeout(
      const Duration(minutes: 2),
    );
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode != 200) {
      throw StateError(
        'Cloudinary image upload failed (${response.statusCode}).',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl = data['secure_url'] as String?;
    final parsedUrl = secureUrl == null ? null : Uri.tryParse(secureUrl);
    if (parsedUrl == null ||
        parsedUrl.scheme != 'https' ||
        parsedUrl.host != 'res.cloudinary.com' ||
        !parsedUrl.path.startsWith('/$cloudName/image/upload/')) {
      throw StateError('Cloudinary returned an invalid image URL.');
    }
    return parsedUrl.toString();
  }
}
