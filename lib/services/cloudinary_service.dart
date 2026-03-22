import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

class CloudinaryUploadResult {
  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
  });

  final String secureUrl;
  final String publicId;
}

class CloudinaryService {
  Future<CloudinaryUploadResult> uploadImageWithMetadata(File file) async {
    final cloudName = Config.cloudinaryCloudName;
    final preset = Config.cloudinaryUploadPreset;

    if (!Config.isCloudinaryClientUploadConfigured) {
      throw Exception(
        'Cloudinary config missing. Set CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET in .env',
      );
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = preset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Cloudinary upload failed: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl = body['secure_url']?.toString() ?? '';
    final publicId = body['public_id']?.toString() ?? '';
    if (secureUrl.isEmpty) {
      throw Exception('Cloudinary response did not include secure_url');
    }
    if (publicId.isEmpty) {
      throw Exception('Cloudinary response did not include public_id');
    }

    return CloudinaryUploadResult(secureUrl: secureUrl, publicId: publicId);
  }

  Future<String> uploadImage(File file) async {
    final result = await uploadImageWithMetadata(file);
    return result.secureUrl;
  }

  Future<List<String>> uploadImages(List<File> files) async {
    final results = await uploadImagesWithMetadata(files);
    return results.map((e) => e.secureUrl).toList(growable: false);
  }

  Future<List<CloudinaryUploadResult>> uploadImagesWithMetadata(
    List<File> files,
  ) async {
    final urls = <String>[];
    final publicIds = <String>[];
    for (final file in files) {
      try {
        final upload = await uploadImageWithMetadata(file);
        urls.add(upload.secureUrl);
        publicIds.add(upload.publicId);
      } catch (error, stackTrace) {
        debugPrint('Cloudinary upload error: $error\\n$stackTrace');
        rethrow;
      }
    }
    final result = <CloudinaryUploadResult>[];
    for (var i = 0; i < urls.length; i++) {
      result.add(
        CloudinaryUploadResult(
          secureUrl: urls[i],
          publicId: publicIds[i],
        ),
      );
    }
    return result;
  }
}
