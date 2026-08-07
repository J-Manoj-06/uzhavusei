import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/voice_search_service.dart';

enum SpeechState {
  idle,
  listening,
  recognizing,
  searching,
  completed,
  noSpeech,
  error,
}

class SpeechProvider extends ChangeNotifier {
  SpeechState _state = SpeechState.idle;
  String _recognizedText = '';
  double _soundLevel = 0.0;
  String? _errorMessage;
  Timer? _silenceTimer;
  bool _isDisposed = false;

  SpeechState get state => _state;
  String get recognizedText => _recognizedText;
  double get soundLevel => _soundLevel;
  String? get errorMessage => _errorMessage;

  void startVoiceRecognition({
    required Function(String query) onSpeechComplete,
  }) async {
    _state = SpeechState.listening;
    _recognizedText = '';
    _errorMessage = null;
    _soundLevel = 0.0;
    notifyListeners();

    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    // Start 5-second silence check
    _startSilenceTimer();

    await VoiceSearchService.instance.startListening(
      onResult: (text, isFinal) {
        if (_isDisposed) return;
        _resetSilenceTimer();

        _recognizedText = text;
        if (text.isNotEmpty) {
          _state = isFinal ? SpeechState.searching : SpeechState.recognizing;
          notifyListeners();
        }

        if (isFinal && text.trim().isNotEmpty) {
          _state = SpeechState.completed;
          notifyListeners();
          try {
            HapticFeedback.selectionClick();
          } catch (_) {}
          onSpeechComplete(text.trim());
        }
      },
      onStatus: (status) {
        if (_isDisposed) return;
        if (status == 'notListening' && _recognizedText.trim().isEmpty && _state == SpeechState.listening) {
          _state = SpeechState.noSpeech;
          notifyListeners();
        }
      },
      onError: (error) {
        if (_isDisposed) return;
        _cancelSilenceTimer();

        if (error == 'permanently_denied') {
          _state = SpeechState.error;
          _errorMessage = 'Microphone permission is required for voice search.';
        } else if (error == 'permission_denied') {
          _state = SpeechState.error;
          _errorMessage = 'Microphone permission was denied.';
        } else if (_recognizedText.isEmpty) {
          _state = SpeechState.noSpeech;
          _errorMessage = "We couldn't hear anything.";
        }
        notifyListeners();
      },
      onSoundLevelChange: (level) {
        if (_isDisposed) return;
        _soundLevel = level;
        notifyListeners();
      },
    );
  }

  void stopListening({Function(String query)? onSpeechComplete}) async {
    _cancelSilenceTimer();
    await VoiceSearchService.instance.stopListening();

    if (_recognizedText.trim().isNotEmpty && onSpeechComplete != null) {
      _state = SpeechState.completed;
      notifyListeners();
      onSpeechComplete(_recognizedText.trim());
    } else {
      _state = SpeechState.idle;
      notifyListeners();
    }
  }

  void _startSilenceTimer() {
    _cancelSilenceTimer();
    _silenceTimer = Timer(const Duration(seconds: 5), () {
      if (_isDisposed) return;
      if (_recognizedText.isEmpty && _state == SpeechState.listening) {
        VoiceSearchService.instance.stopListening();
        _state = SpeechState.noSpeech;
        _errorMessage = "We couldn't hear anything.";
        notifyListeners();
      }
    });
  }

  void _resetSilenceTimer() {
    _startSilenceTimer();
  }

  void _cancelSilenceTimer() {
    _silenceTimer?.cancel();
  }

  void openAppSettingsPage() {
    openAppSettings();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cancelSilenceTimer();
    VoiceSearchService.instance.cancelListening();
    super.dispose();
  }
}
