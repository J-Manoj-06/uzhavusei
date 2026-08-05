import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserBadge {
  final String id;
  final String title;
  final String icon;
  final String description;
  final DateTime earnedAt;

  UserBadge({
    required this.id,
    required this.title,
    required this.icon,
    required this.description,
    required this.earnedAt,
  });

  factory UserBadge.fromMap(Map<String, dynamic> map) {
    return UserBadge(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      icon: map['icon'] ?? '🏆',
      description: map['description'] ?? '',
      earnedAt: (map['earnedAt'] is Timestamp)
          ? (map['earnedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'icon': icon,
      'description': description,
      'earnedAt': Timestamp.fromDate(earnedAt),
    };
  }
}

class UserAchievementModel {
  final String userId;
  final String userName;
  final int points;
  final int booksRead;
  final int streakDays;
  final List<UserBadge> badges;

  UserAchievementModel({
    required this.userId,
    required this.userName,
    required this.points,
    required this.booksRead,
    required this.streakDays,
    required this.badges,
  });

  factory UserAchievementModel.fromMap(Map<String, dynamic> map, String id) {
    final list = (map['badges'] as List<dynamic>?)
            ?.map((b) => UserBadge.fromMap(b as Map<String, dynamic>))
            .toList() ??
        [];

    return UserAchievementModel(
      userId: id,
      userName: map['userName'] ?? 'Student',
      points: (map['points'] as num?)?.toInt() ?? 0,
      booksRead: (map['booksRead'] as num?)?.toInt() ?? 0,
      streakDays: (map['streakDays'] as num?)?.toInt() ?? 0,
      badges: list,
    );
  }
}

class GamificationService {
  GamificationService._({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static final GamificationService instance = GamificationService._();
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('user_achievements');

  /// Streams achievements for a student.
  Stream<UserAchievementModel?> watchUserAchievements(String userId) {
    if (userId.isEmpty) return Stream.value(null);
    return _collection.doc(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserAchievementModel.fromMap(doc.data()!, doc.id);
    });
  }

  /// Streams Top Reader Leaderboard.
  Stream<List<UserAchievementModel>> watchLeaderboard() {
    return _collection.limit(10).snapshots().map((snap) {
      final list = snap.docs.map((doc) => UserAchievementModel.fromMap(doc.data(), doc.id)).toList();
      list.sort((a, b) => b.points.compareTo(a.points));
      return list;
    });
  }

  /// Awards points & badges on completing a book or returning early.
  Future<void> awardPoints({
    required String userId,
    required String userName,
    required int pointsToAdd,
    UserBadge? newBadge,
  }) async {
    final docRef = _collection.doc(userId);
    final snap = await docRef.get();

    int currentPoints = 0;
    int currentBooks = 0;
    List<dynamic> existingBadges = [];

    if (snap.exists && snap.data() != null) {
      final data = snap.data()!;
      currentPoints = (data['points'] as num?)?.toInt() ?? 0;
      currentBooks = (data['booksRead'] as num?)?.toInt() ?? 0;
      existingBadges = data['badges'] as List<dynamic>? ?? [];
    }

    if (newBadge != null) {
      existingBadges.add(newBadge.toMap());
    }

    await docRef.set({
      'userName': userName,
      'points': currentPoints + pointsToAdd,
      'booksRead': currentBooks + 1,
      'badges': existingBadges,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
