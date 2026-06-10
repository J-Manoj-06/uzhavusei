import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/app_user_model.dart';
import '../../../services/auth_service.dart';

class RegistrationFlowPage extends StatefulWidget {
  const RegistrationFlowPage({super.key, required this.authService});
  final AuthService authService;

  @override
  State<RegistrationFlowPage> createState() => _RegistrationFlowPageState();
}

class _RegistrationFlowPageState extends State<RegistrationFlowPage> {
  int _currentStep = 0;
  bool _submitting = false;

  final _phoneController = TextEditingController(text: '+91 ');
  final _otpController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _verificationId;
  int? _resendToken;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      _showError('Please enter a valid phone number with country code (e.g. +91...)');
      return;
    }

    setState(() => _submitting = true);

    try {
      await widget.authService.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolution (Android)
          // We can automatically advance to the next step
          if (!mounted) return;
          setState(() {
            _otpController.text = credential.smsCode ?? '';
            _currentStep = 2; // Jump to details if auto verified, or keep at 1 to let them know.
            _submitting = false;
          });
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() => _submitting = false);
          _showError(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _currentStep = 1;
            _submitting = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
            });
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showError(e.toString());
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      _showError('Please enter OTP');
      return;
    }

    setState(() => _submitting = true);

    try {
      final credential = widget.authService.getPhoneAuthCredential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      
      // We don't sign in here because we need to link it to an email/password account
      // or we just trust the OTP is correct since getPhoneAuthCredential doesn't immediately 
      // throw until it's used. Wait, we should verify the credential.
      // To do that without signing in right now, we can actually just proceed.
      // If we want to strictly verify, we could do signInWithCredential but that logs them in with Phone.
      // According to Firebase best practices for this, we will just proceed to Step 2 
      // and let the credential be used or simply rely on the fact they received the OTP.
      // Actually, we can sign them in anonymously, link it, but wait. We can just proceed.
      
      // For simplicity, we proceed to Step 2. If they enter the wrong OTP, it will fail when linking,
      // but since we aren't linking right now, we can't easily verify the OTP validity here without
      // actually signing them in.
      // Wait, let's sign them in with the phone credential, then update their email/password!
      // This is the cleanest way:
      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;
      setState(() {
        _currentStep = 2;
        _submitting = false;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showError(e.message ?? 'Invalid OTP');
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showError(e.toString());
    }
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      // The user is currently signed in via Phone Number!
      // We need to link the email/password credential or update the current user.
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // Create an Email/Password credential
        final credential = EmailAuthProvider.credential(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Link the current Phone-Auth user to the Email/Password credential
        await user.linkWithCredential(credential);
        await user.updateDisplayName(_nameController.text.trim());
        await user.sendEmailVerification();

        final uid = user.uid;
        final appUser = AppUserModel(
          userId: uid,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          role: '',
          phoneNumber: _phoneController.text.trim(),
          profileImage: '',
          language: 'en',
          createdAt: DateTime.now(),
          emailVerified: false,
          phoneVerified: true,
        );
        await FirebaseFirestore.instance.collection('users').doc(uid).set(appUser.toMap());
        
        if (!mounted) return;
        Navigator.pop(context); // Pop back to AuthGate, which will route to VerifyEmailPage
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showError(e.message ?? 'Error creating account');
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showError(e.toString());
    }
  }

  Widget _buildPhoneStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.phone_android, size: 80, color: Color(0xFF4CAF50)),
        const SizedBox(height: 24),
        const Text(
          'Verify your phone number',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          enabled: !_submitting,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 24),
        _submitting
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                onPressed: _sendOtp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF43A047),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Send OTP', style: TextStyle(fontSize: 16)),
              ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.message, size: 80, color: Color(0xFF4CAF50)),
        const SizedBox(height: 24),
        const Text(
          'Enter OTP',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text('We sent an SMS to ${_phoneController.text}', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        TextField(
          controller: _otpController,
          enabled: !_submitting,
          decoration: const InputDecoration(
            labelText: '6-digit OTP',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.password),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        _submitting
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                onPressed: _verifyOtp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF43A047),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Verify OTP', style: TextStyle(fontSize: 16)),
              ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Complete your profile',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            enabled: !_submitting,
            decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            enabled: !_submitting,
            decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
            keyboardType: TextInputType.emailAddress,
            validator: (val) {
              if (val == null || val.isEmpty) return 'Required';
              if (!val.contains('@')) return 'Enter valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            enabled: !_submitting,
            decoration: InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            ),
            obscureText: _obscurePassword,
            validator: (val) => val != null && val.length < 6 ? 'Min 6 chars' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmController,
            enabled: !_submitting,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              )
            ),
            obscureText: _obscureConfirmPassword,
            validator: (val) => val != _passwordController.text ? 'Passwords do not match' : null,
          ),
          const SizedBox(height: 24),
          _submitting
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _registerUser,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF43A047),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create Account', style: TextStyle(fontSize: 16)),
                ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: _currentStep == 0
              ? _buildPhoneStep()
              : _currentStep == 1
                  ? _buildOtpStep()
                  : _buildDetailsStep(),
        ),
      ),
    );
  }
}
