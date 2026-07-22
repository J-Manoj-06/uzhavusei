import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';
import 'logger_service.dart';

class ReviewRepository {
  final FirebaseFirestore _firestore;

  ReviewRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('reviews');

  /// Writes a new review document and updates reviewee rating stats in Firestore.
  Future<void> createReview(ReviewModel review) async {
    try {
      final alreadyReviewed = await hasReviewed(
        requestId: review.requestId,
        reviewerId: review.reviewerId,
      );

      if (alreadyReviewed) {
        throw Exception('You have already submitted a review for this request.');
      }

      final docRef = _collection.doc();
      final data = review.toMap();
      data['reviewId'] = docRef.id;

      await docRef.set(data);
      LoggerService.debug('Review created successfully: ${docRef.id}');
    } on FirebaseException catch (e) {
      LoggerService.error('Firestore Error on createReview: ${e.message}', e);
      throw Exception('Failed to submit review: ${e.message}');
    } catch (e) {
      LoggerService.error('Error on createReview: $e', e);
      rethrow;
    }
  }

  /// Checks if the reviewer has already submitted a review for this borrow request.
  Future<bool> hasReviewed({
    required String requestId,
    required String reviewerId,
  }) async {
    try {
      final query = await _collection
          .where('requestId', isEqualTo: requestId)
          .where('reviewerId', isEqualTo: reviewerId)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      LoggerService.error('Error checking review status: $e', e);
      return false;
    }
  }

  /// Stream of recent reviews received by a user.
  Stream<List<ReviewModel>> watchUserReviews(String userId) {
    return _collection
        .where('revieweeId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list =
          snapshot.docs.map((doc) => ReviewModel.fromDoc(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}
