import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/marketplace_equipment_model.dart';
import '../models/borrow_request_model.dart';

class LibrarianAnalyticsSummary {
  final int totalBooksCataloged;
  final int totalPhysicalCopies;
  final int activeLoansCount;
  final int pendingRequestsCount;
  final String topCategory;
  final List<MarketplaceEquipmentModel> mostBorrowedBooks;

  LibrarianAnalyticsSummary({
    required this.totalBooksCataloged,
    required this.totalPhysicalCopies,
    required this.activeLoansCount,
    required this.pendingRequestsCount,
    required this.topCategory,
    required this.mostBorrowedBooks,
  });
}

class LibraryAnalyticsService {
  LibraryAnalyticsService._({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static final LibraryAnalyticsService instance = LibraryAnalyticsService._();
  final FirebaseFirestore _firestore;

  /// Streams realtime librarian circulation & inventory metrics.
  Stream<LibrarianAnalyticsSummary> watchLibrarianMetrics() {
    return _firestore.collection('equipment').snapshots().asyncMap((equipSnap) async {
      final List<MarketplaceEquipmentModel> books = [];

      for (final doc in equipSnap.docs) {
        final item = MarketplaceEquipmentModel.fromDoc(doc);
        if (item.category.toLowerCase().contains('book')) {
          books.add(item);
        }
      }

      try {
        final booksSnap = await _firestore.collection('books').get();
        for (final doc in booksSnap.docs) {
          books.add(MarketplaceEquipmentModel.fromDoc(doc));
        }
      } catch (_) {}

      final Map<String, MarketplaceEquipmentModel> unique = {};
      int totalCopies = 0;
      final Map<String, int> catCounts = {};

      for (final b in books) {
        unique[b.equipmentId] = b;
        totalCopies += b.totalCopies;
        catCounts[b.category] = (catCounts[b.category] ?? 0) + 1;
      }

      String topCat = 'General';
      int maxCatCount = 0;
      catCounts.forEach((cat, itemCount) {
        if (itemCount > maxCatCount) {
          maxCatCount = itemCount;
          topCat = cat;
        }
      });

      int activeLoans = 0;
      int pending = 0;

      try {
        final reqSnap = await _firestore.collection('borrow_requests').get();
        for (final doc in reqSnap.docs) {
          final req = BorrowRequestModel.fromDoc(doc);
          if (req.status == 'Borrowed' || req.status == 'Accepted') activeLoans++;
          if (req.status == 'Requested') pending++;
        }
      } catch (_) {}

      final sortedBooks = unique.values.toList()..sort((a, b) => b.bookingsCount.compareTo(a.bookingsCount));

      return LibrarianAnalyticsSummary(
        totalBooksCataloged: unique.length,
        totalPhysicalCopies: totalCopies,
        activeLoansCount: activeLoans,
        pendingRequestsCount: pending,
        topCategory: topCat,
        mostBorrowedBooks: sortedBooks.take(5).toList(),
      );
    });
  }

  /// Generates clean CSV string formatted reports for exports.
  String generateCsvReport(List<BorrowRequestModel> requests) {
    final StringBuffer sb = StringBuffer();
    sb.writeln('Request ID,Listing Title,Borrower Name,Category,Status,Borrow From,Borrow Until');

    for (final req in requests) {
      final from = req.borrowFrom.toIso8601String().split('T').first;
      final until = req.borrowUntil.toIso8601String().split('T').first;
      sb.writeln('"${req.requestId}","${req.listingTitle}","${req.borrowerName}","${req.category}","${req.status}","$from","$until"');
    }

    return sb.toString();
  }
}
