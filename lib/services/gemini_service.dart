import 'dart:convert';

import 'package:http/http.dart' as http;

class GeminiService {
  // Demo only: never commit real API keys to public repositories.
  static const String apiKey = "AIzaSyAIOLUmvpiQwEZPvQbpm7FtTXDDwDY_YYE";

  Future<String> generateText(String prompt) async {
    const String url =
        'https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=$apiKey';

    final Map<String, dynamic> body = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ]
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        final generatedText =
            data['candidates'][0]['content']['parts'][0]['text'];

        if (generatedText is String) {
          return generatedText;
        }
      }

      return 'Error generating response';
    } catch (_) {
      return 'Error generating response';
    }
  }
}
