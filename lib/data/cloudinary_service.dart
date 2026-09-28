import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../core/constants/cloudinary_constants.dart';
import 'app_error.dart';

class UploadedImage {
  const UploadedImage({
    required this.url,
    required this.publicId,
    required this.fileName,
    required this.sizeBytes,
  });
  final String url, publicId, fileName;
  final int sizeBytes;

  Map<String, dynamic> toMap() => {
    'imageUrl': url,
    'imagePublicId': publicId,
    'imageFileName': fileName,
    'imageSizeBytes': sizeBytes,
  };
}

class CloudinaryService {
  CloudinaryService({
    this.cloudName = CloudinaryConstants.cloudName,
    this.uploadPreset = CloudinaryConstants.uploadPreset,
    this.client,
  });

  final String cloudName, uploadPreset;
  final http.Client? client;
  static const maxImageBytes = 10 * 1024 * 1024;

  void validateConfiguration() {
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(cloudName) ||
        uploadPreset.trim().isEmpty) {
      throw const AppException(
        'Cloudinary is not configured. Set CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET when building the app.',
      );
    }
  }

  Future<UploadedImage> uploadImage(XFile image) async {
    validateConfiguration();
    final length = await image.length();
    if (length == 0 || length > maxImageBytes) {
      throw const AppException('Choose a non-empty image of 10 MB or less.');
    }
    final bytes = await image.readAsBytes();
    if (bytes.isEmpty || bytes.length > maxImageBytes) {
      throw const AppException('Choose a non-empty image of 10 MB or less.');
    }
    final fileName = image.name.isEmpty ? 'product-image' : image.name;
    final client = this.client ?? http.Client();
    try {
      final request =
          http.MultipartRequest(
              'POST',
              Uri.https('api.cloudinary.com', '/v1_1/$cloudName/image/upload'),
            )
            ..fields['upload_preset'] = uploadPreset
            ..files.add(
              http.MultipartFile.fromBytes('file', bytes, filename: fileName),
            );
      final response = await (() async => http.Response.fromStream(
        await client.send(request),
      ))().timeout(const Duration(seconds: 60));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppException(
          'Image upload failed (${response.statusCode}). Check your connection and unsigned upload preset.',
        );
      }
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic> ||
          data['secure_url'] is! String ||
          data['public_id'] is! String ||
          (data['public_id'] as String).trim().isEmpty) {
        throw const AppException(
          'Cloudinary returned an invalid image response.',
        );
      }
      final uri = Uri.tryParse(data['secure_url'] as String);
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
        throw const AppException(
          'Cloudinary did not return a secure image URL.',
        );
      }
      return UploadedImage(
        url: uri.toString(),
        publicId: data['public_id'] as String,
        fileName: fileName,
        sizeBytes: bytes.length,
      );
    } on TimeoutException {
      throw const AppException('Image upload timed out. Please try again.');
    } on FormatException {
      throw const AppException(
        'Cloudinary returned an invalid response. Please try again.',
      );
    } on http.ClientException {
      throw const AppException(
        'Image upload failed. Check your connection and try again.',
      );
    } finally {
      if (this.client == null) client.close();
    }
  }
}
