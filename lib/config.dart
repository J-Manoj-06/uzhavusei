
class Config {
  static const String apiKey =
      ''; // Replace with your actual API key

  static const String apiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String modelName = 'gemini-2.0-flash';

  static bool get isApiKeySet => apiKey.isNotEmpty;
}
