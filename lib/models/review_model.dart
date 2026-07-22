import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String reviewId;
  final String requestId;
  final String listingId;
  final String reviewerId;
  final String reviewerName;
  final String revieweeId;
  final double rating;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.reviewId,
    required this.requestId,
    required this.listingId,
    required this.reviewerId,
    this.reviewerName = 'Community Member',
    required this.revieweeId,
    required this.rating,
    this.comment = '',
    required this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ReviewModel(
      reviewId: id.isNotEmpty ? id : (map['reviewId'] ?? ''),
      requestId: map['requestId'] ?? '',
      listingId: map['listingId'] ?? '',
      reviewerId: map['reviewerId'] ?? '',
      reviewerName: map['reviewerName'] ?? 'Community Member',
      revieweeId: map['revieweeId'] ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      comment: map['comment'] ?? '',
      createdAt: parseDate(map['createdAt']),
    );
  }

  factory ReviewModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ReviewModel.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'reviewId': reviewId,
      'requestId': requestId,
      'listingId': listingId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'revieweeId': revieweeId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
