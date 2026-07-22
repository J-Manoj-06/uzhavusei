import 'package:cloud_firestore/cloud_firestore.dart';
import 'logger_service.dart';

class SafetyService {
  final FirebaseFirestore _firestore;

  SafetyService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Reports a user for inappropriate behavior, harassment, spam, etc.
  Future<void> reportUser({
    required String reporterId,
    required String targetUserId,
    required String reason,
    String? details,
  }) async {
    try {
      final docRef = _firestore.collection('user_reports').doc();
      await docRef.set({
        'reportId': docRef.id,
        'reporterId': reporterId,
        'targetUserId': targetUserId,
        'reason': reason,
        'details': details ?? '',
        'status': 'Pending',
        'createdAt': Timestamp.now(),
      });
      LoggerService.debug('User report logged: ${docRef.id}');
    } on FirebaseException catch (e) {
      LoggerService.error('Error on reportUser: ${e.message}', e);
      throw Exception('Failed to report user: ${e.message}');
    } catch (e) {
      LoggerService.error('Error on reportUser: $e', e);
      rethrow;
    }
  }

  /// Reports a product listing for inappropriate content, fake info, etc.
  Future<void> reportListing({
    required String reporterId,
    required String listingId,
    required String reason,
    String? details,
  }) async {
    try {
      final docRef = _firestore.collection('listing_reports').doc();
      await docRef.set({
        'reportId': docRef.id,
        'reporterId': reporterId,
        'listingId': listingId,
        'reason': reason,
        'details': details ?? '',
        'status': 'Pending',
        'createdAt': Timestamp.now(),
      });
      LoggerService.debug('Listing report logged: ${docRef.id}');
    } on FirebaseException catch (e) {
      LoggerService.error('Error on reportListing: ${e.message}', e);
      throw Exception('Failed to report listing: ${e.message}');
    } catch (e) {
      LoggerService.error('Error on reportListing: $e', e);
      rethrow;
    }
  }

  /// Blocks a user to prevent future borrow requests or contact.
  Future<void> blockUser({
    required String userId,
    required String blockedUserId,
  }) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('blocked_users')
          .doc(blockedUserId);

      await docRef.set({
        'blockedUserId': blockedUserId,
        'blockedAt': Timestamp.now(),
      });
      LoggerService.debug('User $blockedUserId blocked by $userId');
    } on FirebaseException catch (e) {
      LoggerService.error('Error on blockUser: ${e.message}', e);
      throw Exception('Failed to block user: ${e.message}');
    } catch (e) {
      LoggerService.error('Error on blockUser: $e', e);
      rethrow;
    }
  }

  /// Checks if a target user is blocked by the current user.
  Future<bool> isUserBlocked({
    required String userId,
    required String targetUserId,
  }) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('blocked_users')
          .doc(targetUserId)
          .get();

      return doc.exists;
    } catch (e) {
      LoggerService.error('Error checking block status: $e', e);
      return false;
    }
  }
}
