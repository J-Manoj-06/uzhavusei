import 'dart:convert';

import 'package:http/http.dart' as http;

class DeepSeekService {
  // Demo only. Never commit real API keys to public repositories.
  static const String apiKey = 'YOUR_DEEPSEEK_API_KEY';
  static const String _url = 'https://api.deepseek.com/chat/completions';

  Future<String> generateReply({
    required List<Map<String, String>> chatHistory,
    required String languageCode,
  }) async {
    final body = {
      'model': 'deepseek-chat',
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a friendly agriculture marketplace assistant for farmers. '
                  'Give short, practical answers. '
                  'Reply in the same language as user input. '
                  'If user language is unclear, reply in this language code: $languageCode.'
        },
        ...chatHistory
            .where((item) => item['role'] != null && item['content'] != null)
            .map((item) => {
                  'role': item['role']!,
                  'content': item['content']!,
                }),
      ],
      'temperature': 0.7,
      'max_tokens': 700,
    };

    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text = data['choices']?[0]?['message']?['content'];
        if (text is String && text.trim().isNotEmpty) {
          return text.trim();
        }
      }

      return 'Sorry, I could not generate a response right now.';
    } catch (_) {
      return 'Sorry, I could not generate a response right now.';
    }
  }
}
