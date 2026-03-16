import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseBootstrap {
  static bool _initialized = false;
  static String? _initError;

  static bool get initialized => _initialized;
  static String? get initError => _initError;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _initialized = true;
      _initError = null;
    } catch (error, stackTrace) {
      _initialized = false;
      _initError = error.toString();
      debugPrint('Firebase initialization failed: $error\n$stackTrace');
    }
  }
}
