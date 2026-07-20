import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProductIdService {
  ProductIdService._();
  static final ProductIdService instance = ProductIdService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generates a new unique Product ID of format BRW-######.
  Future<String> generateProductId() async {
    int maxIdNum = 0;
    try {
      // Find the listing with the highest productId
      final snapshot = await _firestore
          .collection('equipment')
          .orderBy('productIdLower', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final String? lastId = data['productId'] as String?;
        if (lastId != null && lastId.startsWith('BRW-')) {
          final numPart = lastId.substring(4);
          final parsed = int.tryParse(numPart);
          if (parsed != null) {
            maxIdNum = parsed;
          }
        }
      }
    } catch (e) {
      // If ordering fails due to lack of composite index, search all documents to find the max value.
      try {
        final snapshot = await _firestore.collection('equipment').get();
        for (final doc in snapshot.docs) {
          final lastId = doc.data()['productId'] as String?;
          if (lastId != null && lastId.startsWith('BRW-')) {
            final parsed = int.tryParse(lastId.substring(4));
            if (parsed != null && parsed > maxIdNum) {
              maxIdNum = parsed;
            }
          }
        }
      } catch (_) {}
    }

    int nextNum = maxIdNum + 1;
    String generatedId = _formatId(nextNum);

    // Validate uniqueness (if duplicate, keep incrementing)
    bool unique = await isUnique(generatedId);
    while (!unique) {
      nextNum++;
      generatedId = _formatId(nextNum);
      unique = await isUnique(generatedId);
    }

    return generatedId;
  }

  /// Formats a number to BRW-######
  String _formatId(int number) {
    final String padded = number.toString().padLeft(6, '0');
    return 'BRW-$padded';
  }

  /// Checks if the given Product ID does not exist in Firestore.
  Future<bool> isUnique(String productId) async {
    final query = await _firestore
        .collection('equipment')
        .where('productIdLower', isEqualTo: productId.toLowerCase())
        .limit(1)
        .get();
    return query.docs.isEmpty;
  }

  /// Copies the Product ID to the clipboard and shows a SnackBar feedback.
  void copyToClipboard(BuildContext context, String productId) {
    Clipboard.setData(ClipboardData(text: productId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Product ID copied successfully.'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Searches for a listing by Product ID.
  /// Returns the Firestore document snapshot if found.
  Future<DocumentSnapshot<Map<String, dynamic>>?> searchByProductId(
      String productId) async {
    final cleanId = productId.trim().toLowerCase();
    final query = await _firestore
        .collection('equipment')
        .where('productIdLower', isEqualTo: cleanId)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      return query.docs.first;
    }
    return null;
  }
}
