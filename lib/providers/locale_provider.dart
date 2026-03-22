import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  String get languageCode => _locale.languageCode;

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }

  void setLanguageCode(String languageCode) {
    final code = languageCode.trim().toLowerCase();
    final normalized = switch (code) {
      'ta' => 'ta',
      'hi' => 'hi',
      _ => 'en',
    };
    setLocale(Locale(normalized));
  }
}
