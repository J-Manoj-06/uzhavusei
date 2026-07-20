import 'dart:convert';

import 'package:http/http.dart' as http;

class DeepSeekService {
  // Demo only. Never commit real API keys to public repositories.
  static const String apiKey = 'YOUR_DEEPSEEK_API_KEY';
  static const String _url = 'https://api.deepseek.com/chat/completions';

  Future<String> generateReply({
    required List<Map<String, String>> chatHistory,
    required String languageCode,
    String? listingContextPrompt,
  }) async {
    final systemPrompt =
        'You are a friendly community marketplace assistant for Borrow. Borrow is a community marketplace where people can rent, lend, buy, and sell resources such as books, farming equipment, construction equipment, and more. '
        'Give short, practical answers. '
        'Reply in the same language as user input. '
        'If user language is unclear, reply in this language code: $languageCode.'
        '${listingContextPrompt != null ? "\n\n$listingContextPrompt" : ""}';

    final body = {
      'model': 'deepseek-chat',
      'messages': [
        {
          'role': 'system',
          'content': systemPrompt,
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
