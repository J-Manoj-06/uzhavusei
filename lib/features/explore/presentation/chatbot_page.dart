import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../providers/locale_provider.dart';
import '../../../services/deepseek_service.dart';
import 'package:UzhavuSei/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CHAT SESSION MODEL
// ─────────────────────────────────────────────────────────────────────────────

class ChatSession {
  final String id;
  final String title;
  final List<Map<String, String>> messages;
  final DateTime timestamp;

  ChatSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'messages': messages,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
        id: json['id'],
        title: json['title'],
        messages: List<Map<String, dynamic>>.from(json['messages'])
            .map((m) => Map<String, String>.from(m))
            .toList(),
        timestamp: DateTime.parse(json['timestamp']),
      );

  ChatSession copyWith({
    String? title,
    List<Map<String, String>>? messages,
    DateTime? timestamp,
  }) {
    return ChatSession(
      id: id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN CHATBOT PAGE
// ─────────────────────────────────────────────────────────────────────────────

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage>
    with SingleTickerProviderStateMixin {
  final DeepSeekService _service = DeepSeekService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<ChatSession> _sessions = [];
  ChatSession? _activeSession;
  bool _chatActive = false;
  bool _isLoading = false;
  bool _isOnline = true;

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _entranceController.forward();
    _loadSessions();
    _checkConnectivity();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  // ── Network Connectivity Check ──────────────────────────────
  Future<void> _checkConnectivity() async {
    try {
      // Direct fast connection check to verify DeepSeek reachability
      final response = await _service.generateReply(
        chatHistory: [
          {'role': 'user', 'content': 'ping'}
        ],
        languageCode: 'en',
      ).timeout(const Duration(seconds: 4));

      setState(() {
        _isOnline = !response.contains('could not generate a response');
      });
    } catch (_) {
      setState(() => _isOnline = false);
    }
  }

  // ── Load & Save Sessions ────────────────────────────────────
  Future<void> _loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getString('borrow_ai_sessions');
      if (sessionsJson != null) {
        final List<dynamic> decoded = jsonDecode(sessionsJson);
        setState(() {
          _sessions = decoded.map((s) => ChatSession.fromJson(s)).toList();
          // Sort newest first
          _sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        });
      }
    } catch (e) {
      debugPrint('[ChatbotPage] Error loading sessions: $e');
    }
  }

  Future<void> _saveSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = jsonEncode(_sessions.map((s) => s.toJson()).toList());
      await prefs.setString('borrow_ai_sessions', sessionsJson);
    } catch (e) {
      debugPrint('[ChatbotPage] Error saving sessions: $e');
    }
  }

  // ── Conversation Flow Actions ───────────────────────────────
  void _startNewSession([String? initialPrompt]) {
    final String newId = DateTime.now().millisecondsSinceEpoch.toString();
    // Default title is the first 4 words of the prompt or "New Conversation"
    String title = 'New Conversation';
    if (initialPrompt != null) {
      final words = initialPrompt.split(' ');
      title = words.take(4).join(' ');
      if (words.length > 4) title += '...';
    }

    final newSession = ChatSession(
      id: newId,
      title: title,
      messages: [],
      timestamp: DateTime.now(),
    );

    setState(() {
      _sessions.insert(0, newSession);
      _activeSession = newSession;
      _chatActive = true;
    });

    _saveSessions();

    if (initialPrompt != null) {
      _sendMessage(initialPrompt);
    }
  }

  void _continueSession(ChatSession session) {
    setState(() {
      _activeSession = session;
      _chatActive = true;
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage([String? overrideText]) async {
    final input = (overrideText ?? _controller.text).trim();
    if (input.isEmpty || _isLoading) return;

    if (overrideText == null) _controller.clear();

    // Ensure we have an active session
    if (_activeSession == null) {
      _startNewSession(input);
      return;
    }

    final languageCode = context.read<LocaleProvider>().languageCode;

    // 1. Add user message
    final updatedMessages = List<Map<String, String>>.from(_activeSession!.messages)
      ..add({'role': 'user', 'content': input});

    // Update title if it was the default "New Conversation"
    String newTitle = _activeSession!.title;
    if (_activeSession!.title == 'New Conversation' || _activeSession!.title.isEmpty) {
      final words = input.split(' ');
      newTitle = words.take(4).join(' ');
      if (words.length > 4) newTitle += '...';
    }

    final updatedSession = _activeSession!.copyWith(
      messages: updatedMessages,
      title: newTitle,
      timestamp: DateTime.now(),
    );

    setState(() {
      _activeSession = updatedSession;
      _isLoading = true;
      // Sync in main list
      final idx = _sessions.indexWhere((s) => s.id == updatedSession.id);
      if (idx != -1) {
        _sessions[idx] = updatedSession;
      }
    });

    _scrollToBottom();
    _saveSessions();

    // 2. Fetch AI Reply
    final reply = await _service.generateReply(
      chatHistory: updatedMessages,
      languageCode: languageCode,
    );

    if (!mounted) return;

    // 3. Add AI Reply
    final finalMessages = List<Map<String, String>>.from(updatedSession.messages)
      ..add({'role': 'assistant', 'content': reply});

    final finalSession = updatedSession.copyWith(
      messages: finalMessages,
      timestamp: DateTime.now(),
    );

    setState(() {
      _activeSession = finalSession;
      _isLoading = false;
      // Sync in main list
      final idx = _sessions.indexWhere((s) => s.id == finalSession.id);
      if (idx != -1) {
        _sessions[idx] = finalSession;
        // Move to top
        _sessions.removeAt(idx);
        _sessions.insert(0, finalSession);
      }
    });

    _scrollToBottom();
    _saveSessions();
  }

  void _clearCurrentChat() {
    if (_activeSession == null) return;

    setState(() {
      final emptySession = _activeSession!.copyWith(
        messages: [],
        timestamp: DateTime.now(),
      );
      _activeSession = emptySession;
      final idx = _sessions.indexWhere((s) => s.id == emptySession.id);
      if (idx != -1) {
        _sessions[idx] = emptySession;
      }
    });
    _saveSessions();
  }

  void _deleteSession(String sessionId) {
    setState(() {
      _sessions.removeWhere((s) => s.id == sessionId);
      if (_activeSession?.id == sessionId) {
        _activeSession = null;
        _chatActive = false;
      }
    });
    _saveSessions();
  }

  void _clearAllSessions() {
    setState(() {
      _sessions.clear();
      _activeSession = null;
      _chatActive = false;
    });
    _saveSessions();
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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text('Select Language',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
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
      backgroundColor: AppColors.background,
      appBar: BorrowAiHeader(
        isOnline: _isOnline,
        chatActive: _chatActive,
        onBack: () {
          setState(() {
            _chatActive = false;
            _activeSession = null;
          });
        },
        onShowLanguage: _showLanguageSheet,
        onClearChat: _chatActive ? _clearCurrentChat : _clearAllSessions,
      ),
      body: Column(
        children: [
          Expanded(
            child: _chatActive
                ? _buildActiveChat()
                : _buildAiHome(localeCode),
          ),
          BorrowAiChatInput(
            controller: _controller,
            focusNode: _focusNode,
            localeCode: localeCode,
            onSubmitted: (text) => _sendMessage(text),
            onChanged: (val) => setState(() {}),
          ),
        ],
      ),
    );
  }

  // ── ACTIVE CHAT SCREEN ───────────────────────────────────────
  Widget _buildActiveChat() {
    final messages = _activeSession?.messages ?? [];

    if (messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, color: AppColors.primary, size: 40),
            SizedBox(height: 16),
            Text(
              'Start of your conversation',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            SizedBox(height: 6),
            Text(
              'Ask me anything about books or equipment!',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isLoading && index == messages.length) {
          return const LoadingState();
        }
        final msgMap = messages[index];
        return _ChatBubble(
          isUser: msgMap['role'] == 'user',
          text: msgMap['content'] ?? '',
          time: DateTime.now(), // Fallback or store timestamp in message
        );
      },
    );
  }

  // ── AI HOME SCREEN ───────────────────────────────────────────
  Widget _buildAiHome(String localeCode) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GreetingSection(),
            const SizedBox(height: 28),
            
            // Reusable QuickActionGrid
            QuickActionGrid(
              onActionTapped: (prompt) {
                _startNewSession(prompt);
              },
            ),
            const SizedBox(height: 28),

            // Reusable SuggestionChips
            SuggestionChips(
              onSuggestionTapped: (prompt) {
                _controller.text = prompt;
                _focusNode.requestFocus();
                setState(() {});
              },
            ),
            const SizedBox(height: 28),

            // Recent Conversations or Empty State Illustration
            if (_sessions.isNotEmpty) ...[
              RecentConversationList(
                sessions: _sessions,
                onSessionSelected: _continueSession,
                onDeleteSession: _deleteSession,
              ),
            ] else ...[
              EmptyState(
                onStartChat: () {
                  _startNewSession();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BORROW AI HEADER (Custom PreferredSizeWidget AppBar)
// ─────────────────────────────────────────────────────────────────────────────

class BorrowAiHeader extends StatelessWidget implements PreferredSizeWidget {
  const BorrowAiHeader({
    super.key,
    required this.isOnline,
    required this.chatActive,
    required this.onBack,
    required this.onShowLanguage,
    required this.onClearChat,
  });

  final bool isOnline;
  final bool chatActive;
  final VoidCallback onBack;
  final VoidCallback onShowLanguage;
  final VoidCallback onClearChat;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      leading: chatActive
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: onBack,
            )
          : null,
      title: Row(
        children: [
          if (!chatActive) const SizedBox(width: 16),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.secondary, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Borrow AI',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isOnline ? AppColors.success : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isOnline ? 'Online • Ready to help' : 'Offline',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        _circularActionButton(
          icon: Icons.language_rounded,
          onPressed: onShowLanguage,
          tooltip: 'Language',
        ),
        const SizedBox(width: 8),
        _circularActionButton(
          icon: chatActive ? Icons.refresh_rounded : Icons.delete_sweep_rounded,
          onPressed: onClearChat,
          tooltip: chatActive ? 'Restart Conversation' : 'Clear Chat History',
        ),
        const SizedBox(width: 16),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFEEEEEE)),
      ),
    );
  }

  Widget _circularActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}

// ─────────────────────────────────────────────────────────────────────────────
// GREETING SECTION
// ─────────────────────────────────────────────────────────────────────────────

class GreetingSection extends StatelessWidget {
  const GreetingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hello 👋',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'How can I help you today?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK ACTION GRID (Responsive Grid view builder)
// ─────────────────────────────────────────────────────────────────────────────

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({super.key, required this.onActionTapped});

  final ValueChanged<String> onActionTapped;

  static const List<Map<String, String>> _actions = [
    {
      'emoji': '📚',
      'title': 'Books',
      'desc': 'Find, compare or understand books.',
      'prompt': 'Suggest books for beginners to borrow.',
    },
    {
      'emoji': '🚜',
      'title': 'Farm Equipment',
      'desc': 'Learn about equipment and rentals.',
      'prompt': 'How do I find or rent farming equipment near me?',
    },
    {
      'emoji': '🏗',
      'title': 'Construction Equipment',
      'desc': 'Explore construction tools and machinery.',
      'prompt': 'What construction tools can I rent on the platform?',
    },
    {
      'emoji': '📍',
      'title': 'Nearby Listings',
      'desc': 'Find items available near your location.',
      'prompt': 'Show me the closest active listings to borrow.',
    },
    {
      'emoji': '🆔',
      'title': 'Search by Product ID',
      'desc': 'Analyze a listing using its Borrow Product ID.',
      'prompt': 'Explain how I can analyze a listing using its Product ID.',
    },
    {
      'emoji': '❓',
      'title': 'How Borrow Works',
      'desc': 'Learn how borrowing, lending and sharing works.',
      'prompt': 'How does borrowing and lending work on this platform?',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 600 ? 3 : 2;
    final double aspectRatio = screenWidth > 600 ? 1.5 : 1.35;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            final act = _actions[index];
            return _QuickActionCard(
              emoji: act['emoji']!,
              title: act['title']!,
              description: act['desc']!,
              onTap: () => onActionTapped(act['prompt']!),
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  const _QuickActionCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isPressed ? AppColors.secondary.withValues(alpha: 0.5) : const Color(0xFFEBEFF0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isPressed
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: _isPressed ? 16 : 8,
                offset: _isPressed ? const Offset(0, 6) : const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 13,
                    color: _isPressed ? AppColors.primary : Colors.grey.shade400,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUGGESTION CHIPS (Horizontal scrolling suggest list)
// ─────────────────────────────────────────────────────────────────────────────

class SuggestionChips extends StatelessWidget {
  const SuggestionChips({super.key, required this.onSuggestionTapped});

  final ValueChanged<String> onSuggestionTapped;

  static const List<String> _prompts = [
    'Recommend Java books',
    'Find nearby tractors',
    'Explain this construction tool',
    'How does borrowing work?',
    'Suggest books for beginners',
    'Show items near me',
    'How do I list my equipment?',
    'What should I check before borrowing?',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Try asking',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _prompts.length,
            itemBuilder: (context, index) {
              final pr = _prompts[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(pr),
                  onPressed: () => onSuggestionTapped(pr),
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  side: const BorderSide(color: Color(0xFFEBEFF0), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RECENT CONVERSATIONS LIST
// ─────────────────────────────────────────────────────────────────────────────

class RecentConversationList extends StatelessWidget {
  const RecentConversationList({
    super.key,
    required this.sessions,
    required this.onSessionSelected,
    required this.onDeleteSession,
  });

  final List<ChatSession> sessions;
  final ValueChanged<ChatSession> onSessionSelected;
  final ValueChanged<String> onDeleteSession;

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${time.day}/${time.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Conversations',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final s = sessions[index];
            final lastMsg = s.messages.isNotEmpty ? s.messages.last['content'] : 'Empty conversation';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEBEFF0)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(
                  s.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  lastMsg ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 18),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(s.timestamp),
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => onSessionSelected(s),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Continue →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                      onPressed: () => onDeleteSession(s.id),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.onStartChat});

  final VoidCallback onStartChat;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBEFF0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.forum_outlined,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ask Borrow AI about books, equipment or using the Borrow app.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: onStartChat,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Start Conversation', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BORROW AI CHAT INPUT
// ─────────────────────────────────────────────────────────────────────────────

class BorrowAiChatInput extends StatelessWidget {
  const BorrowAiChatInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.localeCode,
    required this.onSubmitted,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String localeCode;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onChanged;

  String _hintForLanguage(String code) {
    switch (code) {
      case 'ta':
        return 'ஏதேனும் கேளுங்கள்...';
      case 'hi':
        return 'कुछ भी पूछें...';
      default:
        return 'Ask Borrow AI...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
                constraints: const BoxConstraints(minHeight: 48),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFEBEFF0), width: 1.2),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    const Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.send,
                        style: const TextStyle(fontSize: 14.5, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: _hintForLanguage(localeCode),
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        ),
                        onChanged: onChanged,
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            onSubmitted(val);
                          }
                        },
                      ),
                    ),
                    Icon(Icons.mic_none_rounded, color: Colors.grey.shade400, size: 18),
                    const SizedBox(width: 14),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              child: hasText
                  ? Row(
                      children: [
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            if (controller.text.trim().isNotEmpty) {
                              onSubmitted(controller.text);
                            }
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.secondary, AppColors.primary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHAT MESSAGE BUBBLE
// ─────────────────────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.isUser,
    required this.text,
    required this.time,
  });

  final bool isUser;
  final String text;
  final DateTime time;

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          margin: const EdgeInsets.only(bottom: 12, left: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.secondary, AppColors.primary],
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
                  text,
                  style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.4),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(time),
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      );
    }

    // AI bubble
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        margin: const EdgeInsets.only(bottom: 12, right: 40),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 10, top: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.secondary, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
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
                      border: Border.all(color: const Color(0xFFEBEFF0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _formatTime(time),
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: text));
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

// ─────────────────────────────────────────────────────────────────────────────
// LOADING / TYPING BUBBLE
// ─────────────────────────────────────────────────────────────────────────────

class LoadingState extends StatefulWidget {
  const LoadingState({super.key});

  @override
  State<LoadingState> createState() => _LoadingStateState();
}

class _LoadingStateState extends State<LoadingState>
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 10, bottom: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.secondary, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
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
                  border: Border.all(color: const Color(0xFFEBEFF0)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2)),
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
          const Padding(
            padding: EdgeInsets.only(left: 42, bottom: 8),
            child: Text(
              'Borrow AI is thinking...',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
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
        width: 8,
        height: 8,
        decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
      ),
    );
  }
}
