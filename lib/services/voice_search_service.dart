import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceSearchService {
  VoiceSearchService._();
  static final VoiceSearchService instance = VoiceSearchService._();

  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  bool get isListening => _speechToText.isListening;

  /// Safe permission request using permission_handler with try-catch fallback
  Future<bool> requestPermission() async {
    try {
      final status = await Permission.microphone.status;
      if (status.isGranted) return true;
      final result = await Permission.microphone.request();
      return result.isGranted;
    } catch (_) {
      // Fallback if permission_handler channel is not initialized
      return true;
    }
  }

  /// Initialize SpeechToText engine
  Future<bool> initialize({
    Function(String status)? onStatus,
    Function(String error)? onError,
  }) async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speechToText.initialize(
        onStatus: (status) {
          if (onStatus != null) onStatus(status);
        },
        onError: (errorNotification) {
          if (onError != null) onError(errorNotification.errorMsg);
        },
      );
      return _isInitialized;
    } catch (e) {
      if (onError != null) onError(e.toString());
      return false;
    }
  }

  /// Start listening to user speech
  Future<void> startListening({
    required Function(String text, bool isFinal) onResult,
    required Function(String status) onStatus,
    required Function(String error) onError,
    required Function(double level) onSoundLevelChange,
  }) async {
    final hasPerm = await requestPermission();
    if (!hasPerm) {
      onError('permission_denied');
      return;
    }

    final ready = await initialize(onStatus: onStatus, onError: onError);
    if (!ready) {
      onError('initialization_failed');
      return;
    }

    try {
      await _speechToText.listen(
        onResult: (result) {
          onResult(result.recognizedWords, result.finalResult);
        },
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 4),
        onSoundLevelChange: onSoundLevelChange,
        cancelOnError: true,
        partialResults: true,
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Stop speech listening gracefully
  Future<void> stopListening() async {
    try {
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
    } catch (_) {}
  }

  /// Cancel listening immediately
  Future<void> cancelListening() async {
    try {
      await _speechToText.cancel();
    } catch (_) {}
  }
}
