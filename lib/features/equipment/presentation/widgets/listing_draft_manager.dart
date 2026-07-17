import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ListingDraftManager {
  static Future<File> _getDraftFile(String category) async {
    final directory = await getApplicationDocumentsDirectory();
    final safeName = category.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
    return File('${directory.path}/listing_draft_$safeName.json');
  }

  static Future<void> saveDraft(String category, Map<String, dynamic> data) async {
    try {
      final file = await _getDraftFile(category);
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      // ignore
    }
  }

  static Future<Map<String, dynamic>?> loadDraft(String category) async {
    try {
      final file = await _getDraftFile(category);
      if (await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content) as Map<String, dynamic>;
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  static Future<void> clearDraft(String category) async {
    try {
      final file = await _getDraftFile(category);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // ignore
    }
  }
}
