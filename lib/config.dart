import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  // Backend base URL. Example: http://10.0.2.2:8080 for Android emulator
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8080';

  // Gemini configuration
  static String get apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String apiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String modelName = 'gemini-2.0-flash';

  static bool get isApiKeySet => apiKey.isNotEmpty;
}
