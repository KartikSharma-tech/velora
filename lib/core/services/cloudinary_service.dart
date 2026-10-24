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
    String? roomId;
    if (isProfileUpload) {
      // Profile upload is identified by the absence of chat metadata.
    } else if (folder.startsWith('chat_images/')) {
      roomId = folder.substring('chat_images/'.length);
      if (roomId.isEmpty || roomId.contains('/')) {
        throw ArgumentError('Invalid chat room upload path.');
      }
    } else {
      throw ArgumentError('Unsupported image upload path.');
    }

    final projectId = Firebase.app().options.projectId;
    if (projectId.isEmpty) {
      throw StateError('Firebase project is not configured.');
    }
    final uploadUrl = Uri.https(
      'us-central1-$projectId.cloudfunctions.net',
      '/createCloudinaryUploadSignature',
    );
    final idToken = await user.getIdToken();
    final appCheckToken = await FirebaseAppCheck.instance.getToken();
    if (appCheckToken == null) {
      throw StateError('Unable to verify this app for image upload.');
    }
    final headers = <String, String>{
      HttpHeaders.authorizationHeader: 'Bearer $idToken',
      HttpHeaders.contentTypeHeader: 'application/octet-stream',
      'X-Firebase-AppCheck': appCheckToken,
    };
    if (isProfileUpload) {
      headers['X-Velora-Profile-Upload'] = 'true';
    } else {
      headers['X-Velora-Room-Id'] = roomId!;
      headers['X-Velora-Message-Id'] = publicId;
    }

    final uploadResponse = await http.post(
      uploadUrl,
      headers: headers,
      body: await file.readAsBytes(),
    ).timeout(const Duration(minutes: 2));
    if (uploadResponse.statusCode != 200) {
      throw StateError('Image upload failed.');
    }

    final responseData =
        jsonDecode(uploadResponse.body) as Map<String, dynamic>;
    final secureUrl = responseData['secureUrl'] as String?;
    final cloudName = responseData['cloudName'] as String?;
    if (cloudName == null ||
        !RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(cloudName)) {
      throw StateError('Invalid image upload response.');
    }
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
