import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

import '../../../services/auth_service.dart';
import 'registration_flow_page.dart';

class LoginRegisterPage extends StatefulWidget {
  const LoginRegisterPage({
    super.key,
    required this.authService,
  });

  final AuthService authService;

  @override
  State<LoginRegisterPage> createState() => _LoginRegisterPageState();
}

class _LoginRegisterPageState extends State<LoginRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _submitting = false;
  
  final Color _primaryGreen = const Color(0xFF4CAF50);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildBackground() {
    return Container(color: Colors.white);
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 5,
          )
        ]
      ),
      child: child,
    );
  }

  InputDecoration _glassInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54),
      prefixIcon: Icon(icon, color: Colors.black54),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _primaryGreen, width: 2),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: _primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.eco, color: _primaryGreen, size: 32),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Borrow',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Borrow is a community marketplace where people can rent, lend, buy, and sell resources such as books, farming equipment, construction equipment, and more.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildGlassCard(
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              enabled: !_submitting,
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                              keyboardType: TextInputType.emailAddress,
                              decoration: _glassInputDecoration('Email or Phone Number', Icons.person_outline),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty) return 'Required';
                                if (text.contains('@')) {
                                  final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                                  if (!pattern.hasMatch(text)) return 'Enter a valid email';
                                } else if (text.length < 10) {
                                  return 'Enter a valid phone number';
                                }
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              enabled: !_submitting,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                              decoration: _glassInputDecoration('Password', Icons.lock_outline).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.black54,
                                  ),
                                  onPressed: _submitting
                                      ? null
                                      : () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                ),
                              ),
                              validator: (value) {
                                if ((value ?? '').length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _submitting ? null : _forgotPassword,
                                child: Text('Forgot Password?', style: TextStyle(color: _primaryGreen, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _canSubmit ? _submit : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryGreen,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _submitting
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                              Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Login',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const _OrDivider(),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton.icon(
                                onPressed: _submitting ? null : _continueWithGoogle,
                                icon: const Icon(Icons.g_mobiledata, size: 32, color: Colors.black87),
                                label: const Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('New to Borrow?', style: TextStyle(color: Colors.black87, fontSize: 16)),
                          TextButton(
                            onPressed: _submitting
                                ? null
                                : () {
                                    Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) => RegistrationFlowPage(authService: widget.authService)
                                    ));
                                  },
                            child: Text('Create Account', style: TextStyle(color: _primaryGreen, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _canSubmit {
    return !_submitting &&
        _emailController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
    });

    String loginId = _emailController.text.trim();
    if (!loginId.contains('@') && loginId.isNotEmpty) {
      // It's likely a phone number, format it
      loginId = loginId.replaceAll(RegExp(r'[\s\-]+'), '');
      if (!loginId.startsWith('+')) {
        if (loginId.length == 10) {
          loginId = '+91$loginId';
        } else {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid 10-digit phone number'), backgroundColor: Colors.red));
           setState(() => _submitting = false);
           return;
        }
      }
      
      if (loginId.startsWith('+91') && loginId.length != 13) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Indian phone numbers must be exactly 10 digits'), backgroundColor: Colors.red));
         setState(() => _submitting = false);
         return;
      }
    }

    try {
      await widget.authService.signIn(
        email: loginId,
        password: _passwordController.text,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyAuthError(error)), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email to reset password'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      await widget.authService.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Password reset link sent to your email'), backgroundColor: _primaryGreen),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyAuthError(error)), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _continueWithGoogle() async {
    setState(() {
      _submitting = true;
    });

    try {
      await widget.authService.signInWithGoogle();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyAuthError(error)), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'OR',
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
      ],
    );
  }
}

String _friendlyAuthError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'aborted-by-user':
        return 'Google sign-in was cancelled.';
      case 'network-request-failed':
        return 'Network error. Please check internet and try again.';
      case 'google-sign-in-config-error':
        return 'Google Sign-In config issue. Add SHA-1/SHA-256 in Firebase and use matching google-services.json.';
      case 'google-sign-in-failed':
        return error.message ?? 'Google sign-in failed. Please try again.';
      case 'google-sign-in-plugin-unavailable':
        return 'Google Sign-In plugin not initialized. Stop the app and start it again (hot restart is not enough).';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  if (error is PlatformException) {
    final details = '${error.code} ${error.message ?? ''}'.toLowerCase();
    if (details.contains('apiexception: 10') ||
        details.contains('developer_error')) {
      return 'Google Sign-In config issue. Add SHA-1/SHA-256 in Firebase and use matching google-services.json.';
    }
    if (details.contains('canceled') || details.contains('cancelled')) {
      return 'Google sign-in was cancelled.';
    }
    if (details.contains('network')) {
      return 'Network error. Please check internet and try again.';
    }
  }

  return error.toString();
}
