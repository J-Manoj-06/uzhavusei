import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user_model.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user?.updateDisplayName(name);

    final uid = credential.user?.uid;
    if (uid != null) {
      final user = AppUserModel(
        userId: uid,
        name: name,
        email: email,
        role: '',
        phoneNumber: phoneNumber,
        profileImage: '',
        createdAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(uid).set(user.toMap());
    }

    return credential;
  }

  Future<void> setRole(String role) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final normalizedRole = role.trim().toLowerCase();
    await _firestore.collection('users').doc(uid).set({
      'role': normalizedRole,
      'userId': uid,
      'email': _auth.currentUser?.email ?? '',
      'name': _auth.currentUser?.displayName ?? 'User',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<AppUserModel?> watchCurrentUserProfile() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUserModel.fromDoc(doc);
    });
  }

  Future<AppUserModel?> getCurrentUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUserModel.fromDoc(doc);
  }

  Future<void> signOut() => _auth.signOut();
}
