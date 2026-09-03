import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Uploads images to Cloudinary using an *unsigned* upload preset —
/// no API secret is ever embedded in the app (that would be a
/// security leak; unsigned presets are the correct approach for a
/// mobile client with no backend server of its own).
///
/// ===========================================================
/// SETUP (one-time, free — no credit card required):
/// 1. Create a free account at https://cloudinary.com
/// 2. Dashboard → copy your "Cloud name" → paste it below as
///    [cloudName].
/// 3. Settings (gear icon) → Upload → "Upload presets" →
///    "Add upload preset" → set "Signing Mode" to **Unsigned** →
///    Save → copy the preset name → paste it below as
///    [uploadPreset].
/// ===========================================================
class CloudinaryService {
  const CloudinaryService();

  
static const String cloudName = 'wve0mvba';
  static const String uploadPreset = 'velora_chat';


  static Uri get _uploadUrl => Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

  /// Uploads [file] and returns its public HTTPS URL.
  ///
  /// [folder] keeps chat images organized in the Cloudinary media
  /// library (e.g. `chat_images/{roomId}`), mirroring the old
  /// Firebase Storage path structure.
  Future<String> uploadImage({
    required File file,
    required String folder,
    required String publicId,
  }) async {
    if (cloudName == 'YOUR_CLOUD_NAME' || uploadPreset == 'YOUR_UPLOAD_PRESET') {
      throw StateError(
        'Cloudinary is not configured yet — set cloudName and '
        'uploadPreset in lib/core/services/cloudinary_service.dart',
      );
    }

    final request = http.MultipartRequest('POST', _uploadUrl)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folder
      ..fields['public_id'] = publicId
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception(
        'Cloudinary upload failed (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final url = data['secure_url'] as String?;

    if (url == null || url.isEmpty) {
      throw Exception('Cloudinary response missing secure_url: ${response.body}');
    }

    return url;
  }
}
