import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user_model.dart';

class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream student user profile in real-time from users/{uid}
  Stream<AppUserModel?> watchUserProfile(String uid) {
    if (uid.isEmpty) return Stream.value(null);

    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUserModel.fromDoc(doc);
    });
  }

  /// Stream unread notification count for user
  Stream<int> watchUnreadNotificationCount(String uid) {
    if (uid.isEmpty) return Stream.value(0);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .snapshots()
        .map((snap) {
      return snap.docs.where((doc) {
        final data = doc.data();
        final read = data['read'] ?? data['isRead'] ?? false;
        return read == false;
      }).length;
    });
  }
}
