import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;
  late Map<String, String> _strings;

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('ta'),
    Locale('hi'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final value = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(value != null, 'AppLocalizations not found in context');
    return value!;
  }

  Future<void> load() async {
    final code = locale.languageCode;
    final fallback = await rootBundle.loadString('assets/i18n/en.json');
    final fallbackMap =
        Map<String, dynamic>.from(jsonDecode(fallback) as Map<String, dynamic>);

    Map<String, dynamic> localizedMap = fallbackMap;
    try {
      final jsonString = await rootBundle.loadString('assets/i18n/$code.json');
      localizedMap = Map<String, dynamic>.from(
        jsonDecode(jsonString) as Map<String, dynamic>,
      );
    } catch (_) {
      localizedMap = fallbackMap;
    }

    _strings = <String, String>{};
    for (final entry in fallbackMap.entries) {
      final localizedValue = localizedMap[entry.key] ?? entry.value;
      _strings[entry.key] = localizedValue.toString();
    }
  }

  String tr(String key) => _strings[key] ?? key;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
        (item) => item.languageCode == locale.languageCode,
      );

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
