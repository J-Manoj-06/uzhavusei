import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/app_user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/location_service.dart';
import '../../../services/logger_service.dart';

class VerificationCenterPage extends StatefulWidget {
  const VerificationCenterPage({
    super.key,
    required this.currentUser,
    required this.authService,
  });

  final AppUserModel currentUser;
  final AuthService authService;

  @override
  State<VerificationCenterPage> createState() => _VerificationCenterPageState();
}

class _VerificationCenterPageState extends State<VerificationCenterPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _sendingEmail = false;
  bool _verifyingPhone = false;
  bool _refreshingLocation = false;

  String? _verificationId;
  Timer? _emailStatusTimer;
  AppUserModel? _liveUser;

  @override
  void initState() {
    super.initState();
    _subscribeToUserChanges();
    _startEmailStatusChecking();
  }

  void _subscribeToUserChanges() {
    widget.authService.watchCurrentUserProfile().listen((user) {
      if (user != null && mounted) {
        setState(() {
          _liveUser = user;
        });
      }
    });
  }

  void _startEmailStatusChecking() {
    // Periodically reload user authentication state to see if email gets verified
    _emailStatusTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        if (user.emailVerified) {
          final live = _liveUser ?? widget.currentUser;
          if (!live.emailVerified) {
            await _db.collection('users').doc(user.uid).update({'emailVerified': true});
            LoggerService.debug('Email verified state synchronized to Firestore');
          }
          timer.cancel();
        }
      }
    });
  }

  @override
  void dispose() {
    _emailStatusTimer?.cancel();
    super.dispose();
  }

  AppUserModel get _user => _liveUser ?? widget.currentUser;

  Future<void> _sendEmailVerification() async {
    setState(() => _sendingEmail = true);
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.sendEmailVerification();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification email sent! Please check your inbox.'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
        }
      }
    } catch (e) {
      LoggerService.error('Error sending verification email', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send email verification: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingEmail = false);
    }
  }

  Future<void> _verifyLocation() async {
    setState(() => _refreshingLocation = true);
    try {
      final result = await LocationService.instance.getCurrentLocation();
      if (result is LocationSuccess) {
        final loc = result.location;
        await _db.collection('users').doc(_user.userId).update({
          'latitude': loc.latitude,
          'longitude': loc.longitude,
          'village': loc.area,
          'district': loc.city,
          'state': loc.state,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location verified successfully!'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
        }
      } else if (result is LocationFailure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.reason), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      LoggerService.error('Error verifying location', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to acquire location permission or GPS lock.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _refreshingLocation = false);
    }
  }

  void _showPhoneVerifyDialog() {
    final phoneController = TextEditingController(text: _user.phoneNumber);
    final otpController = TextEditingController();
    bool otpSent = false;
    String? localError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Verify Phone Number', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (localError != null) ...[
                    Text(localError!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    const SizedBox(height: 8),
                  ],
                  if (!otpSent) ...[
                    const Text('Enter your phone number to receive a verification OTP code via SMS.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '+919876543210',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ] else ...[
                    Text('SMS verification OTP code sent to ${phoneController.text}. Please enter the 6-digit code below.', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: otpController,
                      decoration: InputDecoration(
                        labelText: 'OTP Code',
                        hintText: '123456',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: _verifyingPhone ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF6F7A6B))),
              ),
              ElevatedButton(
                onPressed: _verifyingPhone
                    ? null
                    : () async {
                        if (!otpSent) {
                          final num = phoneController.text.trim();
                          if (num.isEmpty) {
                            setDialogState(() => localError = 'Phone number cannot be empty.');
                            return;
                          }
                          final nav = Navigator.of(ctx);
                          setDialogState(() {
                            _verifyingPhone = true;
                            localError = null;
                          });
                          try {
                            await widget.authService.verifyPhoneNumber(
                              phoneNumber: num,
                              verificationCompleted: (PhoneAuthCredential credential) async {
                                final authResult = await _auth.signInWithCredential(credential);
                                await _db.collection('users').doc(authResult.user!.uid).update({'phoneVerified': true});
                                nav.pop();
                              },
                              verificationFailed: (FirebaseAuthException e) {
                                setDialogState(() {
                                  _verifyingPhone = false;
                                  localError = e.message ?? 'Verification failed.';
                                });
                              },
                              codeSent: (String vId, int? token) {
                                setDialogState(() {
                                  _verifyingPhone = false;
                                  _verificationId = vId;
                                  otpSent = true;
                                });
                              },
                              codeAutoRetrievalTimeout: (String vId) {
                                _verificationId = vId;
                              },
                            );
                          } catch (e) {
                            setDialogState(() {
                              _verifyingPhone = false;
                              localError = e.toString();
                            });
                          }
                        } else {
                          final otp = otpController.text.trim();
                          if (otp.isEmpty) {
                            setDialogState(() => localError = 'OTP code cannot be empty.');
                            return;
                          }
                          setDialogState(() {
                            _verifyingPhone = true;
                            localError = null;
                          });
                          final nav = Navigator.of(ctx);
                          final sm = ScaffoldMessenger.of(context);
                          try {
                            final credential = widget.authService.getPhoneAuthCredential(
                              verificationId: _verificationId!,
                              smsCode: otp,
                            );
                            await _auth.currentUser?.linkWithCredential(credential);
                            await _db.collection('users').doc(_user.userId).update({
                              'phoneVerified': true,
                              'phoneNumber': phoneController.text.trim(),
                            });
                            nav.pop();
                            sm.showSnackBar(
                              const SnackBar(
                                content: Text('Phone number verified successfully!'),
                                backgroundColor: Color(0xFF2E7D32),
                              ),
                            );
                          } catch (e) {
                            setDialogState(() {
                              _verifyingPhone = false;
                              localError = 'Invalid verification code. Please try again.';
                            });
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
                child: _verifyingPhone
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(otpSent ? 'Verify' : 'Send OTP'),
              ),
            ],
          );
        },
      ),
    );
  }

  int _getVerificationCount() {
    int count = 0;
    if (_user.phoneVerified) count++;
    if ((_auth.currentUser?.emailVerified ?? false) || _user.emailVerified) count++;
    if (_user.latitude != null && _user.longitude != null && _user.latitude != 0.0 && _user.longitude != 0.0) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final verifiedCount = _getVerificationCount();
    final allVerified = verifiedCount == 3;

    final phoneVerified = _user.phoneVerified;
    final emailVerified = (_auth.currentUser?.emailVerified ?? false) || _user.emailVerified;
    final locVerified = _user.latitude != null && _user.longitude != null && _user.latitude != 0.0 && _user.longitude != 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text('Verification Center', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEBEFF0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.01),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      allVerified ? Icons.verified : Icons.verified_user_outlined,
                      color: allVerified ? const Color(0xFF2E7D32) : Colors.amber,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      allVerified ? "🎉 You're fully verified." : 'Complete Verifications',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      allVerified
                          ? 'Your Borrow profile is ready to share and request items.'
                          : 'Verify your contact and location details to build community trust.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: verifiedCount / 3,
                      backgroundColor: Colors.grey.shade100,
                      color: allVerified ? const Color(0xFF2E7D32) : Colors.amber,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$verifiedCount / 3 Verified',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              const Text('Required Verifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A1A))),
              const SizedBox(height: 16),

              // 1. Phone Card
              _buildVerificationCard(
                prefix: '📱',
                title: 'Phone Verification',
                isVerified: phoneVerified,
                onAction: _showPhoneVerifyDialog,
                actionLabel: 'Verify Now',
                isLoading: _verifyingPhone,
              ),
              const SizedBox(height: 16),

              // 2. Email Card
              _buildVerificationCard(
                prefix: '📧',
                title: 'Email Verification',
                isVerified: emailVerified,
                onAction: _sendEmailVerification,
                actionLabel: 'Send Verification Email',
                isLoading: _sendingEmail,
              ),
              const SizedBox(height: 16),

              // 3. Location Card
              _buildVerificationCard(
                prefix: '📍',
                title: 'Location Verification',
                isVerified: locVerified,
                onAction: _verifyLocation,
                actionLabel: 'Verify Location',
                isLoading: _refreshingLocation,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationCard({
    required String prefix,
    required String title,
    required bool isVerified,
    required VoidCallback onAction,
    required String actionLabel,
    required bool isLoading,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEFF0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(prefix, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1A1A))),
                const SizedBox(height: 4),
                _buildBadge(isVerified ? 'Verified' : 'Not Verified', isVerified),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isVerified || isLoading ? null : onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade100,
              disabledForegroundColor: Colors.grey.shade400,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: isLoading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E7D32)))
                : Text(isVerified ? 'Verified' : 'Verify', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, bool isVerified) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isVerified ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isVerified ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
        ),
      ),
    );
  }
}
