Map<String, String> normalizeLocalizedField(
  dynamic field, {
  String fallback = '',
}) {
  if (field is Map) {
    final normalized = <String, String>{
      'en': (field['en'] ?? '').toString().trim(),
      'ta': (field['ta'] ?? '').toString().trim(),
      'hi': (field['hi'] ?? '').toString().trim(),
    };
    if (normalized['en']!.isEmpty && fallback.trim().isNotEmpty) {
      normalized['en'] = fallback.trim();
    }
    if (normalized['ta']!.isEmpty && normalized['en']!.isNotEmpty) {
      normalized['ta'] = normalized['en']!;
    }
    if (normalized['hi']!.isEmpty && normalized['en']!.isNotEmpty) {
      normalized['hi'] = normalized['en']!;
    }
    return normalized;
  }

  final text = (field ?? fallback).toString().trim();
  return <String, String>{
    'en': text,
    'ta': text,
    'hi': text,
  };
}

String getLocalizedText(Map field, String lang) {
  final code = lang.trim().toLowerCase();
  final selected = (field[code] ?? '').toString().trim();
  if (selected.isNotEmpty) return selected;
  final english = (field['en'] ?? '').toString().trim();
  if (english.isNotEmpty) return english;
  for (final value in field.values) {
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return '';
}
