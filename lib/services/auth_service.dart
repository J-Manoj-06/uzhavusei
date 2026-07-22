import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user_model.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  GoogleSignIn? _googleSignIn;

  GoogleSignIn get _google => _googleSignIn ??= GoogleSignIn();

  Stream<User?> authStateChanges() => _auth.userChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    String actualEmail = email.trim();
    if (!actualEmail.contains('@')) {
      final snapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: actualEmail)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        actualEmail = snapshot.docs.first.data()['email'] as String;
      } else {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found with this phone number.',
        );
      }
    }
    return _auth.signInWithEmailAndPassword(email: actualEmail, password: password);
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(PhoneAuthCredential) verificationCompleted,
    required void Function(FirebaseAuthException) verificationFailed,
    required void Function(String verificationId, int? resendToken) codeSent,
    required void Function(String verificationId) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  PhoneAuthCredential getPhoneAuthCredential({
    required String verificationId,
    required String smsCode,
  }) {
    return PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
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
    await credential.user?.sendEmailVerification();

    final uid = credential.user?.uid;
    if (uid != null) {
      final user = AppUserModel(
        userId: uid,
        name: name,
        email: email,
        role: '',
        phoneNumber: phoneNumber,
        profileImage: '',
        language: 'en',
        createdAt: DateTime.now(),
        emailVerified: false,
        phoneVerified: true,
      );
      await _firestore.collection('users').doc(uid).set(user.toMap());
    }

    return credential;
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      UserCredential credential;

      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        credential = await _auth.signInWithPopup(provider);
      } else {
        final account = await _google.signIn();
        if (account == null) {
          throw FirebaseAuthException(
            code: 'aborted-by-user',
            message: 'Google sign in was cancelled.',
          );
        }

        final googleAuth = await account.authentication;
        final authCredential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        credential = await _auth.signInWithCredential(authCredential);
      }

      await _upsertCurrentUserProfile();
      return credential;
    } on MissingPluginException {
      throw FirebaseAuthException(
        code: 'google-sign-in-plugin-unavailable',
        message:
            'Google Sign-In plugin is not registered. Stop the app and start it again.',
      );
    } on PlatformException catch (error) {
      final details = '${error.code} ${error.message ?? ''}'.toLowerCase();

      if (details.contains('unable to establish connection on channel') ||
          details.contains('google_sign_in_android.googlesigninapi.init') ||
          details.contains('channel-error')) {
        throw FirebaseAuthException(
          code: 'google-sign-in-plugin-unavailable',
          message:
              'Google Sign-In plugin is not initialized. Do a full app restart (hot restart is not enough).',
        );
      }

      if (details.contains('canceled') || details.contains('cancelled')) {
        throw FirebaseAuthException(
          code: 'aborted-by-user',
          message: 'Google sign in was cancelled.',
        );
      }

      if (details.contains('network')) {
        throw FirebaseAuthException(
          code: 'network-request-failed',
          message: 'Network error. Check internet and try again.',
        );
      }

      if (details.contains('apiexception: 10') ||
          details.contains('developer_error') ||
          details.contains('sign_in_failed')) {
        throw FirebaseAuthException(
          code: 'google-sign-in-config-error',
          message:
              'Google Sign-In is not configured correctly for this app build.',
        );
      }

      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: error.message ?? 'Google sign in failed.',
      );
    } catch (error) {
      final details = error.toString().toLowerCase();
      if (details.contains('unable to establish connection on channel') ||
          details.contains('google_sign_in_android.googlesigninapi.init') ||
          details.contains('channel-error')) {
        throw FirebaseAuthException(
          code: 'google-sign-in-plugin-unavailable',
          message:
              'Google Sign-In plugin is not initialized. Do a full app restart (hot restart is not enough).',
        );
      }
      rethrow;
    }
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
      'language': 'en',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateCurrentUserProfile({
    required String name,
    required String phoneNumber,
    required String profileImage,
    String? username,
    String? bio,
    String? selectedState,
    double? latitude,
    double? longitude,
    DateTime? locationUpdatedAt,
    double? accuracy,
    @Deprecated('Use selectedState instead') String? state,
    @Deprecated('No longer used') String? district,
    @Deprecated('No longer used') String? city,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User is not signed in');
    }

    await _auth.currentUser?.updateDisplayName(name);

    final finalState = selectedState ?? state;

    await _firestore.collection('users').doc(uid).set({
      'name': name,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      if (username != null) 'username': username,
      if (bio != null) 'bio': bio,
      if (finalState != null) 'selectedState': finalState,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (locationUpdatedAt != null) 'locationUpdatedAt': Timestamp.fromDate(locationUpdatedAt),
      if (accuracy != null) 'accuracy': accuracy,
      'district': FieldValue.delete(),
      'city': FieldValue.delete(),
      'address': FieldValue.delete(),
      'placemark': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }


  Future<void> updateLanguage(String languageCode) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User is not signed in');
    }
    await _firestore.collection('users').doc(uid).set({
      'language': languageCode,
      'updatedAt': FieldValue.serverTimestamp(),
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

  Future<void> _upsertCurrentUserProfile() async {
    final user = _auth.currentUser;
    final uid = user?.uid;
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).set({
      'userId': uid,
      'email': user?.email ?? '',
      'name': user?.displayName ?? 'User',
      'profileImage': user?.photoURL ?? '',
      'phoneNumber': user?.phoneNumber ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'role': '',
      'language': 'en',
    }, SetOptions(merge: true));
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (_googleSignIn != null) {
      await _googleSignIn!.signOut();
    }
  }
}
