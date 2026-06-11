import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final FocusNode _focusNode = FocusNode();

  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _showSuggestions = true;

  static const Color _green = Color(0xFF4CAF50);
  static const Color _darkGreen = Color(0xFF2E7D32);

  // Suggested quick prompts
  static const List<Map<String, String>> _suggestions = [
    {'emoji': '🌾', 'label': 'Crop Recommendation', 'prompt': 'What crops should I grow this season?'},
    {'emoji': '🚜', 'label': 'Find Equipment', 'prompt': 'How do I find equipment for rent nearby?'},
    {'emoji': '💰', 'label': 'Marketplace Help', 'prompt': 'How can I sell my farm produce on the marketplace?'},
    {'emoji': '📈', 'label': 'Market Prices', 'prompt': 'What are the current market prices for vegetables?'},
    {'emoji': '🌦', 'label': 'Weather Tips', 'prompt': 'How does weather affect my crop planning?'},
    {'emoji': '🏛', 'label': 'Govt. Schemes', 'prompt': 'What government schemes are available for farmers?'},
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? overrideText]) async {
    final input = (overrideText ?? _controller.text).trim();
    if (input.isEmpty || _isLoading) return;

    final languageCode = context.read<LocaleProvider>().languageCode;

    setState(() {
      _messages.add(_ChatMessage(text: input, isUser: true, time: DateTime.now()));
      _isLoading = true;
      _showSuggestions = false;
      if (overrideText == null) _controller.clear();
    });
    _scrollToBottom();

    final chatHistory = _messages
        .where((m) => m.text.trim().isNotEmpty)
        .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text})
        .toList(growable: false);

    final reply = await _service.generateReply(
      chatHistory: chatHistory,
      languageCode: languageCode,
    );

    if (!mounted) return;

    setState(() {
      _messages.add(_ChatMessage(text: reply, isUser: false, time: DateTime.now()));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _showSuggestions = true;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _showLanguageSheet() {
    final localeProvider = context.read<LocaleProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text('Select Language', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _langTile(localeProvider, 'English', 'en', '🇬🇧'),
            _langTile(localeProvider, 'தமிழ் (Tamil)', 'ta', '🇮🇳'),
            _langTile(localeProvider, 'हिन्दी (Hindi)', 'hi', '🇮🇳'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _langTile(LocaleProvider provider, String label, String code, String flag) {
    final isSelected = provider.languageCode == code;
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 22)),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: _green) : null,
      onTap: () {
        provider.setLocale(Locale(code));
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = context.watch<LocaleProvider>().languageCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: _buildAppBar(localeCode),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isLoading && index == _messages.length) {
                        return const _TypingBubble();
                      }
                      return _ChatBubble(message: _messages[index]);
                    },
                  ),
          ),
          _buildInputBar(localeCode),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String localeCode) {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1A1A1A),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(left: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF66BB6A), _darkGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI Farming Assistant',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
              ),
              Row(
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text('Online', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.language_rounded),
          onPressed: _showLanguageSheet,
          tooltip: 'Language',
        ),
        IconButton(
          icon: const Icon(Icons.delete_sweep_rounded),
          onPressed: _clearChat,
          tooltip: 'Clear chat',
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFEEEEEE)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome text
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A), height: 1.3),
              children: [
                TextSpan(text: 'Hello, Farmer '),
                TextSpan(text: '👋', style: TextStyle(fontSize: 26)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'How can I help your farm today?',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.4),
          ),
          const SizedBox(height: 28),

          // Suggestion chips
          Text(
            'Quick questions',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _suggestions.map((s) => _SuggestionChip(
              emoji: s['emoji']!,
              label: s['label']!,
              onTap: () => _sendMessage(s['prompt']),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _capabilityRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final s = _suggestions[i];
          return GestureDetector(
            onTap: () => _sendMessage(s['prompt']),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFDDDDDD)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s['emoji']!, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    s['label']!,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar(String localeCode) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 52),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F4),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
                  decoration: InputDecoration(
                    hintText: _hintForLanguage(localeCode),
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Send button
            AnimatedScale(
              scale: _controller.text.trim().isNotEmpty ? 1.0 : 0.85,
              duration: const Duration(milliseconds: 150),
              child: GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _controller.text.trim().isNotEmpty
                          ? [const Color(0xFF66BB6A), _darkGreen]
                          : [Colors.grey.shade300, Colors.grey.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: _controller.text.trim().isNotEmpty
                        ? [
                            BoxShadow(
                              color: _green.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _hintForLanguage(String code) {
    switch (code) {
      case 'ta':
        return 'விவசாயம் பற்றி கேளுங்கள்...';
      case 'hi':
        return 'खेती के बारे में पूछें...';
      default:
        return 'Ask anything about farming...';
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  Suggestion Chip
// ─────────────────────────────────────────────────────────────
class _SuggestionChip extends StatefulWidget {
  const _SuggestionChip({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  State<_SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<_SuggestionChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _pressed ? const Color(0xFFE8F5E9) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _pressed ? const Color(0xFF4CAF50) : const Color(0xFFE0E0E0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _pressed ? const Color(0xFF2E7D32) : const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Chat Message Model
// ─────────────────────────────────────────────────────────────
class _ChatMessage {
  _ChatMessage({required this.text, required this.isUser, required this.time});
  final String text;
  final bool isUser;
  final DateTime time;
}

// ─────────────────────────────────────────────────────────────
//  Chat Bubble
// ─────────────────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});
  final _ChatMessage message;

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.4),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.time),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      );
    }

    // AI message
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        margin: const EdgeInsets.only(bottom: 12, right: 48),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI avatar
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 10, top: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.eco_rounded, color: Colors.white, size: 16),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      message.text,
                      style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 14.5,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _formatTime(message.time),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: message.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied to clipboard'),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Icon(Icons.copy_rounded, size: 13, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Typing Indicator
// ─────────────────────────────────────────────────────────────
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _dot1, _dot2, _dot3;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _dot1 = _buildDotAnim(0.0);
    _dot2 = _buildDotAnim(0.2);
    _dot3 = _buildDotAnim(0.4);
  }

  Animation<double> _buildDotAnim(double delay) => TweenSequence([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 30),
        TweenSequenceItem(tween: Tween(begin: -6.0, end: 0.0), weight: 30),
        TweenSequenceItem(tween: ConstantTween(0.0), weight: 40),
      ]).animate(CurvedAnimation(
        parent: _ctrl,
        curve: Interval(delay, delay + 0.6, curve: Curves.easeInOut),
      ));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32, height: 32,
            margin: const EdgeInsets.only(right: 10, bottom: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 16),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Dot(offset: _dot1.value),
                  const SizedBox(width: 4),
                  _Dot(offset: _dot2.value),
                  const SizedBox(width: 4),
                  _Dot(offset: _dot3.value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.offset});
  final double offset;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, offset),
      child: Container(
        width: 8, height: 8,
        decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
      ),
    );
  }
}
