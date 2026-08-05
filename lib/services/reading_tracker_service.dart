import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReadingProgressModel {
  final String userId;
  final String bookId;
  final String bookTitle;
  final int pagesRead;
  final int totalPages;
  final int readingStreak;
  final int booksCompleted;
  final DateTime lastReadAt;

  ReadingProgressModel({
    required this.userId,
    required this.bookId,
    required this.bookTitle,
    required this.pagesRead,
    required this.totalPages,
    required this.readingStreak,
    required this.booksCompleted,
    required this.lastReadAt,
  });

  double get percentage => totalPages > 0 ? (pagesRead / totalPages * 100).clamp(0, 100) : 0;

  factory ReadingProgressModel.fromMap(Map<String, dynamic> map, String id) {
    return ReadingProgressModel(
      userId: map['userId'] ?? id,
      bookId: map['bookId'] ?? '',
      bookTitle: map['bookTitle'] ?? '',
      pagesRead: (map['pagesRead'] as num?)?.toInt() ?? 0,
      totalPages: (map['totalPages'] as num?)?.toInt() ?? 100,
      readingStreak: (map['readingStreak'] as num?)?.toInt() ?? 1,
      booksCompleted: (map['booksCompleted'] as num?)?.toInt() ?? 0,
      lastReadAt: (map['lastReadAt'] is Timestamp)
          ? (map['lastReadAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'pagesRead': pagesRead,
      'totalPages': totalPages,
      'readingStreak': readingStreak,
      'booksCompleted': booksCompleted,
      'lastReadAt': Timestamp.fromDate(lastReadAt),
    };
  }
}

class ReadingTrackerService {
  ReadingTrackerService._({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static final ReadingTrackerService instance = ReadingTrackerService._();
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('user_reading_progress');

  /// Streams active reading progress for a student.
  Stream<ReadingProgressModel?> watchReadingProgress(String userId) {
    if (userId.isEmpty) return Stream.value(null);
    return _collection.doc(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return ReadingProgressModel.fromMap(doc.data()!, doc.id);
    });
  }

  /// Updates current reading progress and increments streak.
  Future<void> updateProgress({
    required String userId,
    required String bookId,
    required String bookTitle,
    required int pagesRead,
    required int totalPages,
  }) async {
    final docRef = _collection.doc(userId);
    final snap = await docRef.get();

    int streak = 1;
    int completed = 0;

    if (snap.exists && snap.data() != null) {
      final prev = ReadingProgressModel.fromMap(snap.data()!, snap.id);
      completed = prev.booksCompleted;
      final now = DateTime.now();
      final diff = now.difference(prev.lastReadAt).inHours;
      if (diff < 36) {
        streak = prev.readingStreak + (diff > 12 ? 1 : 0);
      }
    }

    if (pagesRead >= totalPages && totalPages > 0) {
      completed += 1;
    }

    final model = ReadingProgressModel(
      userId: userId,
      bookId: bookId,
      bookTitle: bookTitle,
      pagesRead: pagesRead,
      totalPages: totalPages,
      readingStreak: streak,
      booksCompleted: completed,
      lastReadAt: DateTime.now(),
    );

    await docRef.set(model.toMap(), SetOptions(merge: true));
  }
}
