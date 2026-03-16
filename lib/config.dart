import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  // Backend base URL. Example: http://10.0.2.2:8080 for Android emulator
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8080';

  // Gemini configuration
  static String get apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String get razorpayKey => dotenv.env['RAZORPAY_KEY_ID'] ?? '';
  static String get cloudinaryCloudName =>
      dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get cloudinaryUploadPreset =>
      dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';
  static String get cloudinaryApiSecret =>
      dotenv.env['CLOUDINARY_API_SECRET'] ?? '';
  static const String apiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String modelName = 'gemini-2.0-flash';

  static bool get isApiKeySet => apiKey.isNotEmpty;

  static bool get isCloudinaryClientUploadConfigured =>
      cloudinaryCloudName.isNotEmpty && cloudinaryUploadPreset.isNotEmpty;
}
