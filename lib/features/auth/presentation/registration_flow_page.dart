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

  final _accountFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  
  final _profileFormKey = GlobalKey<FormState>();
  final _landAreaController = TextEditingController();
  final _serviceRangeController = TextEditingController();
  final _primaryCropsController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _verificationId;
  int? _resendToken;
  
  bool _otpSent = false;
  bool _phoneVerified = false;
  bool _emailLinked = false;
  bool _emailVerificationSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _landAreaController.dispose();
    _serviceRangeController.dispose();
    _primaryCropsController.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.green,
    ));
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
          if (!mounted) return;
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            setState(() {
              _otpController.text = credential.smsCode ?? '';
              _phoneVerified = true;
              _submitting = false;
            });
            _showSuccess('Phone verified automatically!');
          } catch(e) {
            setState(() => _submitting = false);
            _showError(e.toString());
          }
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
            _otpSent = true;
            _submitting = false;
          });
          _showSuccess('OTP Sent to $phone');
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
      
      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;
      setState(() {
        _phoneVerified = true;
        _submitting = false;
      });
      _showSuccess('Phone successfully verified!');
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

  Future<void> _linkAccountAndSendEmail() async {
    if (!_accountFormKey.currentState!.validate()) return;
    
    setState(() => _submitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        final credential = EmailAuthProvider.credential(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        await user.linkWithCredential(credential);
        await user.updateDisplayName(_nameController.text.trim());
        await user.sendEmailVerification();

        if (!mounted) return;
        setState(() {
           _emailLinked = true;
           _emailVerificationSent = true;
           _submitting = false;
        });
        _showSuccess('Verification email sent! Please check your inbox.');
      } else {
        throw Exception("You must verify phone number first.");
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      // Wait, if the user account is already linked (e.g. they hit Continue again), we shouldn't fail.
      if (e.code == 'credential-already-in-use') {
         setState(() {
           _emailLinked = true;
           _emailVerificationSent = true;
         });
      } else {
         _showError(e.message ?? 'Error creating account');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showError(e.toString());
    }
  }

  Future<void> _checkEmailVerified() async {
    setState(() => _submitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        if (user.emailVerified) {
          _showSuccess('Email is verified!');
          setState(() {
             _submitting = false;
          });
        } else {
          _showError('Email is not verified yet. Please check your inbox.');
          setState(() {
             _submitting = false;
          });
        }
      }
    } catch(e) {
      setState(() => _submitting = false);
      _showError(e.toString());
    }
  }

  Future<void> _saveProfileAndComplete() async {
    if (!_profileFormKey.currentState!.validate()) return;
    
    setState(() => _submitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Refresh to check if they clicked the email link
        await user.reload();
        
        final uid = user.uid;
        final appUser = AppUserModel(
          userId: uid,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          role: 'farmer', // default role
          phoneNumber: _phoneController.text.trim(),
          profileImage: '',
          language: 'en',
          createdAt: DateTime.now(),
          emailVerified: user.emailVerified,
          phoneVerified: true,
          landArea: _landAreaController.text.trim(),
          serviceRange: _serviceRangeController.text.trim(),
          primaryCrops: _primaryCropsController.text.trim(),
        );
        
        await FirebaseFirestore.instance.collection('users').doc(uid).set(appUser.toMap());
        
        if (!mounted) return;
        Navigator.pop(context); // Pop back to AuthGate
      }
    } catch(e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showError(e.toString());
    }
  }

  Widget _buildStepControls(ControlsDetails details) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        children: <Widget>[
          if (_currentStep < 2)
            ElevatedButton(
              onPressed: details.onStepContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
              child: const Text('Continue'),
            ),
          if (_currentStep == 2)
             ElevatedButton(
              onPressed: details.onStepContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
              child: const Text('Complete Profile'),
            ),
          const SizedBox(width: 12),
          if (_currentStep > 0)
            TextButton(
              onPressed: details.onStepCancel,
              child: const Text('Back', style: TextStyle(color: Colors.grey)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep == 0) {
              if (!_phoneVerified) {
                _showError('Please verify your phone number first.');
                return;
              }
              setState(() => _currentStep += 1);
            } else if (_currentStep == 1) {
              if (!_emailLinked) {
                _linkAccountAndSendEmail();
              } else {
                setState(() => _currentStep += 1);
              }
            } else if (_currentStep == 2) {
              _saveProfileAndComplete();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep -= 1);
            }
          },
          controlsBuilder: (BuildContext context, ControlsDetails details) {
            return _buildStepControls(details);
          },
          steps: [
            // STEP 1: PHONE VERIFICATION
            Step(
              title: const Text('Phone Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: const Text('Secure your account'),
              isActive: _currentStep >= 0,
              state: _phoneVerified ? StepState.complete : StepState.editing,
              content: Column(
                children: [
                  TextField(
                    controller: _phoneController,
                    enabled: !_submitting && !_phoneVerified,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  if (!_phoneVerified)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _sendOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black,
                            ),
                            child: Text(_otpSent ? 'Resend OTP' : 'Send OTP'),
                          ),
                        ),
                      ],
                    ),
                  if (_otpSent && !_phoneVerified) ...[
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _verifyOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Verify OTP'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_phoneVerified)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Phone Verified', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            // STEP 2: ACCOUNT DETAILS & EMAIL VERIFICATION
            Step(
              title: const Text('Account Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: const Text('Name, Email & Password'),
              isActive: _currentStep >= 1,
              state: _emailLinked ? StepState.complete : StepState.editing,
              content: Form(
                key: _accountFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      enabled: !_submitting && !_emailLinked,
                      decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      enabled: !_submitting && !_emailLinked,
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
                      enabled: !_submitting && !_emailLinked,
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
                      enabled: !_submitting && !_emailLinked,
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
                    if (_emailVerificationSent) ...[
                       const SizedBox(height: 16),
                       Container(
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(
                           color: Colors.blue[50],
                           borderRadius: BorderRadius.circular(8),
                           border: Border.all(color: Colors.blue.shade200),
                         ),
                         child: Column(
                           children: [
                             const Text(
                               'A verification link has been sent to your email. Please click the link to verify your email address.',
                               style: TextStyle(color: Colors.blueGrey),
                             ),
                             const SizedBox(height: 12),
                             ElevatedButton.icon(
                               onPressed: _submitting ? null : _checkEmailVerified,
                               icon: const Icon(Icons.refresh),
                               label: const Text('I have verified'),
                             )
                           ],
                         ),
                       )
                    ]
                  ],
                ),
              ),
            ),

            // STEP 3: FARMING PROFILE
            Step(
              title: const Text('Farming Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: const Text('Optional details'),
              isActive: _currentStep >= 2,
              content: Form(
                key: _profileFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _landAreaController,
                      enabled: !_submitting,
                      decoration: const InputDecoration(
                        labelText: 'Land Area (e.g., 5 Acres)', 
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.landscape),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _serviceRangeController,
                      enabled: !_submitting,
                      decoration: const InputDecoration(
                        labelText: 'Service Range (e.g., 15 km)', 
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.map),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _primaryCropsController,
                      enabled: !_submitting,
                      decoration: const InputDecoration(
                        labelText: 'Primary Crops (e.g., Paddy, Corn)', 
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.grass),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
