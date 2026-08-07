import 'package:flutter/material.dart';
import '../providers/speech_provider.dart';
import '../theme/app_theme.dart';

class VoiceBottomSheet extends StatefulWidget {
  final ValueChanged<String> onResult;

  const VoiceBottomSheet({super.key, required this.onResult});

  static Future<void> show(BuildContext context, {required ValueChanged<String> onResult}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VoiceBottomSheet(onResult: onResult),
    );
  }

  @override
  State<VoiceBottomSheet> createState() => _VoiceBottomSheetState();
}

class _VoiceBottomSheetState extends State<VoiceBottomSheet> with SingleTickerProviderStateMixin {
  late final SpeechProvider _speechProvider;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _speechProvider = SpeechProvider();
    _speechProvider.addListener(_onSpeechStateChanged);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _speechProvider.startVoiceRecognition(
      onSpeechComplete: (text) {
        if (!mounted) return;
        Navigator.pop(context);
        widget.onResult(text);
      },
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speechProvider.removeListener(_onSpeechStateChanged);
    _speechProvider.dispose();
    super.dispose();
  }

  void _onSpeechStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = _speechProvider.state;
    final text = _speechProvider.recognizedText;
    final errorMsg = _speechProvider.errorMessage;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 24),

          // Glowing Mic / Waveform Animation
          _buildAnimatedMicrophone(state),

          const SizedBox(height: 24),

          // State Title & Subtitle
          _buildStatusText(state, text, errorMsg),

          const SizedBox(height: 24),

          // Action Buttons depending on state
          _buildActionButtons(state),
        ],
      ),
    );
  }

  Widget _buildAnimatedMicrophone(SpeechState state) {
    final isListening = state == SpeechState.listening || state == SpeechState.recognizing;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = isListening ? (1.0 + (_pulseController.value * 0.15)) : 1.0;
        final glowOpacity = isListening ? (0.2 + (_pulseController.value * 0.3)) : 0.0;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer Glowing Ripple Wave
            if (isListening)
              Transform.scale(
                scale: scale * 1.3,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(glowOpacity),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

            // Main Microphone Circle
            Transform.scale(
              scale: scale,
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: isListening ? AppColors.primary : Colors.grey.shade300,
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (isListening)
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Icon(
                  isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusText(SpeechState state, String text, String? errorMsg) {
    if (state == SpeechState.noSpeech || state == SpeechState.error) {
      return Column(
        children: [
          Text(
            errorMsg ?? "We couldn't hear anything.",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Please check your microphone permissions and try speaking clearly.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      );
    }

    if (state == SpeechState.searching) {
      return Column(
        children: const [
          Text(
            'Searching Borrow...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          SizedBox(height: 6),
          CircularProgressIndicator(strokeWidth: 2),
        ],
      );
    }

    return Column(
      children: [
        Text(
          state == SpeechState.recognizing ? 'Recognizing speech...' : '🎤 Listening...',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text.isNotEmpty ? '"$text"' : 'Speak the name of a book or equipment.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: text.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
            color: text.isNotEmpty ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(SpeechState state) {
    if (state == SpeechState.noSpeech) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _speechProvider.startVoiceRecognition(
                  onSpeechComplete: (text) {
                    if (!mounted) return;
                    Navigator.pop(context);
                    widget.onResult(text);
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Try Again'),
            ),
          ),
        ],
      );
    }

    if (state == SpeechState.error && errorMsgContainsPermission(_speechProvider.errorMessage)) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _speechProvider.openAppSettingsPage(),
          icon: const Icon(Icons.settings_rounded, size: 18),
          label: const Text('Open Settings'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          _speechProvider.stopListening(
            onSpeechComplete: (text) {
              if (!mounted) return;
              Navigator.pop(context);
              widget.onResult(text);
            },
          );
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Color(0xFFCBD5E1)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text(
          'Stop Listening',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  bool errorMsgContainsPermission(String? msg) {
    if (msg == null) return false;
    return msg.contains('permission') || msg.contains('Permission');
  }
}
