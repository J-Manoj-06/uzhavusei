import 'package:cloud_functions/cloud_functions.dart';

class EquipmentTranslationService {
  EquipmentTranslationService({FirebaseFunctions? functions})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1');

  final FirebaseFunctions _functions;

  Future<Map<String, Map<String, String>>> translateEquipmentFields({
    required String baseLanguage,
    required String title,
    required String description,
    required String category,
  }) async {
    final callable = _functions.httpsCallable('translateEquipmentFields');
    final response = await callable.call({
      'baseLanguage': baseLanguage,
      'title': title,
      'description': description,
      'category': category,
    });

    final data = Map<String, dynamic>.from(response.data as Map);

    return {
      'title': _mapField(data['title']),
      'description': _mapField(data['description']),
      'category': _mapField(data['category']),
    };
  }

  static Map<String, String> _mapField(dynamic raw) {
    final map =
        raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    return {
      'en': (map['en'] ?? '').toString().trim(),
      'ta': (map['ta'] ?? '').toString().trim(),
      'hi': (map['hi'] ?? '').toString().trim(),
    };
  }
}
