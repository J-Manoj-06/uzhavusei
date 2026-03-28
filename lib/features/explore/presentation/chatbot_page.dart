import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/locale_provider.dart';
import '../../../services/deepseek_service.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final DeepSeekService _service = DeepSeekService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addWelcomeMessage();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    final languageCode = context.read<LocaleProvider>().languageCode;
    if (_messages.isNotEmpty) return;

    setState(() {
      _messages.add(
        _ChatMessage(
          text: _welcomeText(languageCode),
          isUser: false,
          time: DateTime.now(),
        ),
      );
    });
  }

  String _welcomeText(String languageCode) {
    switch (languageCode) {
      case 'ta':
        return 'வணக்கம். உழவர் சந்தை, இயந்திரம், வாடகை, பயிர் மற்றும் பணம் தொடர்பான கேள்விகளை கேளுங்கள்.';
      case 'hi':
        return 'नमस्ते। आप खेती, मशीन किराया, फसल, भुगतान और मार्केटप्लेस से जुड़े सवाल पूछ सकते हैं।';
      default:
        return 'Hello. Ask me about farming, equipment rental, crop planning, payments, and marketplace help.';
    }
  }

  Future<void> _sendMessage() async {
    final input = _controller.text.trim();
    if (input.isEmpty || _isLoading) return;

    final languageCode = context.read<LocaleProvider>().languageCode;

    setState(() {
      _messages
          .add(_ChatMessage(text: input, isUser: true, time: DateTime.now()));
      _isLoading = true;
      _controller.clear();
    });
    _scrollToBottom();

    final chatHistory = _messages
        .where((message) => message.text.trim().isNotEmpty)
        .map(
          (message) => {
            'role': message.isUser ? 'user' : 'assistant',
            'content': message.text,
          },
        )
        .toList(growable: false);

    final reply = await _service.generateReply(
      chatHistory: chatHistory,
      languageCode: languageCode,
    );

    if (!mounted) return;

    setState(() {
      _messages.add(
        _ChatMessage(text: reply, isUser: false, time: DateTime.now()),
      );
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _clearChat() {
    final languageCode = context.read<LocaleProvider>().languageCode;
    setState(() {
      _messages
        ..clear()
        ..add(
          _ChatMessage(
            text: _welcomeText(languageCode),
            isUser: false,
            time: DateTime.now(),
          ),
        );
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = context.watch<LocaleProvider>().languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForLanguage(localeCode)),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: _clearTextForLanguage(localeCode),
            onPressed: _clearChat,
            icon: const Icon(Icons.delete_sweep_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return const _TypingBubble();
                }
                return _ChatBubble(message: _messages[index]);
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: _hintForLanguage(localeCode),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: _sendMessage,
                    backgroundColor: const Color(0xFF4CAF50),
                    mini: true,
                    child: const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _titleForLanguage(String languageCode) {
    switch (languageCode) {
      case 'ta':
        return 'உழவு உதவி அரட்டை';
      case 'hi':
        return 'कृषि सहायता चैट';
      default:
        return 'Farm Assistant Chat';
    }
  }

  String _hintForLanguage(String languageCode) {
    switch (languageCode) {
      case 'ta':
        return 'உங்கள் கேள்வியை தட்டச்சு செய்யவும்...';
      case 'hi':
        return 'अपना सवाल लिखें...';
      default:
        return 'Type your question...';
    }
  }

  String _clearTextForLanguage(String languageCode) {
    switch (languageCode) {
      case 'ta':
        return 'அரட்டை அழிக்க';
      case 'hi':
        return 'चैट साफ करें';
      default:
        return 'Clear chat';
    }
  }
}

class _ChatMessage {
  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });

  final String text;
  final bool isUser;
  final DateTime time;
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final alignment =
        message.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = message.isUser ? const Color(0xFF4CAF50) : Colors.white;
    final textColor = message.isUser ? Colors.white : const Color(0xFF1F1F1F);

    return Align(
      alignment: alignment,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border:
              message.isUser ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: textColor, fontSize: 14),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
