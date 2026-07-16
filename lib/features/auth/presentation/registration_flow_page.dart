import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pinput/pinput.dart';
import 'dart:ui';
import '../../../models/app_user_model.dart';
import '../../../services/auth_service.dart';

class RegistrationFlowPage extends StatefulWidget {
  const RegistrationFlowPage({super.key, required this.authService});
  final AuthService authService;

  @override
  State<RegistrationFlowPage> createState() => _RegistrationFlowPageState();
}

class _RegistrationFlowPageState extends State<RegistrationFlowPage> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _submitting = false;

  // -- Colors
  final Color _primaryGreen = const Color(0xFF4CAF50);
  final Color _darkGreen = const Color(0xFF2E7D32);
  final Color _lightGreen = const Color(0xFFE8F5E9);
  
  // -- Step 1: Phone
  final _phoneController = TextEditingController(text: '+91 ');
  final _otpController = TextEditingController();
  String? _verificationId;
  int? _resendToken;
  bool _otpSent = false;
  bool _phoneVerified = false;

  // -- Step 2: Account
  final _accountFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _emailLinked = false;

  // -- Step 3: Profile
  final _profileFormKey = GlobalKey<FormState>();
  String _userType = 'Farmer'; 
  final _stateController = TextEditingController();
  final _districtController = TextEditingController();
  final _villageController = TextEditingController();
  String _farmSize = '< 1 Acre'; 
  String _landType = 'Wetland'; 
  
  final List<String> _selectedCrops = [];
  final List<String> _cropOptions = [
    'Paddy', 'Sugarcane', 'Cotton', 'Groundnut', 'Banana', 'Coconut', 'Vegetables', 'Fruits'
  ];

  bool _ownsEquipment = false;
  final List<String> _selectedEquipment = [];
  final List<String> _equipmentOptions = [
    'Tractor', 'Rotavator', 'Harvester', 'Sprayer', 'Seed Drill', 'Cultivator'
  ];

  final List<String> _selectedServices = [];
  final List<String> _serviceOptions = [
    'Rent Equipment', 'Lease Equipment', 'Buy Inputs', 'Sell Produce', 'Find Labour', 'Transport Services'
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _villageController.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: _primaryGreen));
  }

  void _nextPage() {
    if (_currentPage < 3) {
      setState(() => _currentPage++);
      _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    }
  }

  double get _profileCompletionPercentage {
    int total = 4;
    int filled = 1; // user type
    if (_stateController.text.isNotEmpty) filled++;
    if (_selectedCrops.isNotEmpty) filled++;
    if (_selectedServices.isNotEmpty) filled++;
    return filled / total;
  }

  // --- LOGIC METHODS ---
  Future<void> _sendOtp() async {
    String phone = _phoneController.text.trim();
    // Remove all spaces and dashes
    phone = phone.replaceAll(RegExp(r'[\s\-]+'), '');
    
    // Automatically add +91 if missing
    if (!phone.startsWith('+')) {
      if (phone.length == 10) {
        phone = '+91$phone';
      } else {
        _showError('Enter a valid 10-digit phone number');
        return;
      }
    }

    if (phone.startsWith('+91') && phone.length != 13) {
      _showError('Indian phone numbers must be exactly 10 digits');
      return;
    }

    if (phone.length < 10 || phone.length > 15) {
      _showError('Invalid phone number length');
      return;
    }
    
    setState(() => _submitting = true);

    try {
      // Check if phone number is already registered
      try {
        final QuerySnapshot existingUser = await FirebaseFirestore.instance
            .collection('users')
            .where('phoneNumber', isEqualTo: phone)
            .limit(1)
            .get();

        if (existingUser.docs.isNotEmpty) {
          if (!mounted) return;
          setState(() => _submitting = false);
          _showError('This number is already registered. Please login instead.');
          return;
        }
      } on FirebaseException catch (e) {
        // If firestore rules haven't been deployed yet, this will throw permission-denied.
        if (e.code != 'permission-denied') rethrow;
        // If permission denied, we skip the pre-check and let the post-OTP check handle it
      }

      await widget.authService.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (!mounted) return;
          try {
            final authResult = await FirebaseAuth.instance.signInWithCredential(credential);
            
            // Check if user already exists in Firestore
            final userDoc = await FirebaseFirestore.instance.collection('users').doc(authResult.user!.uid).get();
            if (userDoc.exists) {
               await FirebaseAuth.instance.signOut();
               if (!mounted) return;
               setState(() {
                  _submitting = false;
                  _otpSent = false;
               });
               _showError('This number is already registered. Please login instead.');
               return;
            }

            if (!mounted) return;
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
          _showSuccess('OTP Sent');
        },
        codeAutoRetrievalTimeout: (String vId) {
          if (mounted) setState(() => _verificationId = vId);
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
    if (otp.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final credential = widget.authService.getPhoneAuthCredential(verificationId: _verificationId!, smsCode: otp);
      final authResult = await FirebaseAuth.instance.signInWithCredential(credential);
      
      // Check if user already exists
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(authResult.user!.uid).get();
      if (userDoc.exists) {
         await FirebaseAuth.instance.signOut();
         if (!mounted) return;
         setState(() {
            _submitting = false;
            _otpSent = false;
            _otpController.clear();
         });
         _showError('This number is already registered. Please login instead.');
         return;
      }

      if (!mounted) return;
      setState(() {
        _phoneVerified = true;
        _submitting = false;
      });
      _showSuccess('Phone verified!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showError('Invalid OTP');
    }
  }

  Future<void> _linkAccountAndNext() async {
    if (!_accountFormKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final credential = EmailAuthProvider.credential(email: _emailController.text.trim(), password: _passwordController.text);
        try {
            await user.linkWithCredential(credential);
            await user.updateDisplayName(_nameController.text.trim());
        } catch(e) {
             // Ignore if already linked during retry
        }
        setState(() {
           _emailLinked = true;
           _submitting = false;
        });
        _nextPage();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showError(e.toString());
    }
  }

  Future<void> _saveProfileAndFinish() async {
    if (!_profileFormKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    
    String phone = _phoneController.text.trim();
    phone = phone.replaceAll(RegExp(r'[\s\-]+'), '');
    if (!phone.startsWith('+')) phone = '+91$phone';

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final uid = user.uid;
        final appUser = AppUserModel(
          userId: uid,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          role: _userType.toLowerCase(),
          phoneNumber: phone,
          profileImage: '',
          language: 'en',
          createdAt: DateTime.now(),
          emailVerified: user.emailVerified,
          phoneVerified: true,
          landArea: _farmSize,
          landType: _landType,
          primaryCrops: _selectedCrops.join(', '),
          state: _stateController.text.trim(),
          district: _districtController.text.trim(),
          village: _villageController.text.trim(),
          ownedEquipment: _ownsEquipment ? _selectedEquipment : [],
          preferredServices: _selectedServices,
        );
        await FirebaseFirestore.instance.collection('users').doc(uid).set(appUser.toMap());
        if (!mounted) return;
        setState(() => _submitting = false);
        _nextPage(); // Go to Final Success Page
      }
    } catch(e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showError(e.toString());
    }
  }

  // --- UI WIDGETS ---

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

  Widget _buildTopBar() {
    return Row(
      children: [
        if (_currentPage > 0 && _currentPage < 3)
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
            onPressed: _submitting ? null : _prevPage,
          ),
        const Spacer(),
        if (_currentPage < 3)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              'Step ${_currentPage + 1} of 3',
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
          )
      ],
    );
  }

  // --- PAGES ---

  Widget _buildStep1Phone() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Verify Your\nMobile Number", style: TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold, height: 1.2)),
          const SizedBox(height: 8),
          const Text("Let's secure your Borrow account", style: TextStyle(color: Colors.black54, fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 40),
          _buildGlassCard(
            child: Column(
              children: [
                TextField(
                  controller: _phoneController,
                  enabled: !_submitting && !_phoneVerified,
                  style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
                  decoration: _glassInputDecoration('Phone Number', Icons.phone),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),
                if (!_phoneVerified && !_otpSent)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _submitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Send OTP', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (_otpSent && !_phoneVerified) ...[
                  Pinput(
                    controller: _otpController,
                    length: 6,
                    defaultPinTheme: PinTheme(
                      width: 50,
                      height: 60,
                      textStyle: const TextStyle(fontSize: 22, color: Colors.black, fontWeight: FontWeight.w600),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                    ),
                    focusedPinTheme: PinTheme(
                      width: 50,
                      height: 60,
                      textStyle: const TextStyle(fontSize: 22, color: Colors.black, fontWeight: FontWeight.w600),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _primaryGreen, width: 2)),
                    ),
                    onCompleted: (pin) => _verifyOtp(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _submitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Verify & Continue', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
                if (_phoneVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _primaryGreen.withOpacity(0.3))
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: _primaryGreen, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Phone Verified: ${_phoneController.text.trim()}',
                            style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          if (_phoneVerified) ...[
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(backgroundColor: _primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('Continue to Account Details', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildStep2Account() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Create Your\nAccount", style: TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold, height: 1.2)),
          const SizedBox(height: 8),
          const Text("Tell us about yourself", style: TextStyle(color: Colors.black54, fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 40),
          _buildGlassCard(
            child: Form(
              key: _accountFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                    decoration: _glassInputDecoration('Full Name', Icons.person),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                    keyboardType: TextInputType.emailAddress,
                    decoration: _glassInputDecoration('Email Address', Icons.email),
                    validator: (val) => val!.contains('@') ? null : 'Enter valid email',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                    decoration: _glassInputDecoration('Password', Icons.lock).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.black54),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      )
                    ),
                    validator: (val) => (val??'').length < 6 ? 'Min 6 chars' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: _obscureConfirmPassword,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                    decoration: _glassInputDecoration('Confirm Password', Icons.lock_outline).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.black54),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      )
                    ),
                    validator: (val) => val != _passwordController.text ? 'Passwords do not match' : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _submitting ? null : _linkAccountAndNext,
              style: ElevatedButton.styleFrom(backgroundColor: _primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: _submitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Continue to Profile', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChipSelector(List<String> options, List<String> selected, StateSetter stateSetter) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(option, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
          selected: isSelected,
          selectedColor: _primaryGreen,
          backgroundColor: Colors.white,
          side: BorderSide(color: isSelected ? _primaryGreen : Colors.grey.shade300),
          checkmarkColor: Colors.white,
          onSelected: (bool val) {
            stateSetter(() {
              if (val) selected.add(option);
              else selected.remove(option);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildStep3Profile() {
    return StatefulBuilder(
      builder: (context, setStateLocal) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Build Your\nFarming Profile", style: TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold, height: 1.2)),
            const SizedBox(height: 8),
            const Text("Help us personalize your experience", style: TextStyle(color: Colors.black54, fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
            Expanded(
              child: _buildGlassCard(
                child: SingleChildScrollView(
                  child: Form(
                    key: _profileFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('I am a...', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          children: ['Farmer', 'Equipment Owner', 'Both'].map((type) {
                            final isSel = _userType.toLowerCase() == type.toLowerCase();
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setStateLocal(() => _userType = type),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSel ? _primaryGreen : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSel ? _primaryGreen : Colors.grey.shade300,
                                      width: 1.5,
                                    )
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(type, style: TextStyle(color: isSel ? Colors.white : Colors.black87, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        const Text('Location', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _stateController,
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                          decoration: _glassInputDecoration('State', Icons.map),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _districtController,
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                          decoration: _glassInputDecoration('District', Icons.location_city),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _villageController,
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                          decoration: _glassInputDecoration('Village/Town', Icons.home),
                        ),
                        const SizedBox(height: 24),
                        const Text('Farm Information', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _farmSize,
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                          iconEnabledColor: Colors.black54,
                          decoration: _glassInputDecoration('Farm Size', Icons.landscape),
                          items: ['< 1 Acre', '1–5 Acres', '5–10 Acres', '10+ Acres'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (val) { setStateLocal(() => _farmSize = val!); },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _landType,
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                          iconEnabledColor: Colors.black54,
                          decoration: _glassInputDecoration('Land Type', Icons.grass),
                          items: ['Wetland', 'Dryland', 'Mixed'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (val) { setStateLocal(() => _landType = val!); },
                        ),
                        const SizedBox(height: 24),
                        const Text('Primary Crops', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildChipSelector(_cropOptions, _selectedCrops, setStateLocal),
                        const SizedBox(height: 24),
                        SwitchListTile(
                          title: const Text('Do you own equipment?', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                          value: _ownsEquipment,
                          activeColor: Colors.white,
                          activeTrackColor: _primaryGreen,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade300)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          onChanged: (val) { setStateLocal(() => _ownsEquipment = val); },
                        ),
                        if (_ownsEquipment) ...[
                          const SizedBox(height: 12),
                          _buildChipSelector(_equipmentOptions, _selectedEquipment, setStateLocal),
                        ],
                        const SizedBox(height: 24),
                        const Text('Preferred Services', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildChipSelector(_serviceOptions, _selectedServices, setStateLocal),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submitting ? null : _saveProfileAndFinish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                ),
                child: _submitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Complete Registration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        );
      },
    );
  }

  Widget _buildFinalSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: _primaryGreen, size: 100),
              ),
              const SizedBox(height: 32),
              const Text("Welcome to\nBorrow", textAlign: TextAlign.center, style: TextStyle(color: Colors.black, fontSize: 40, fontWeight: FontWeight.bold, height: 1.1)),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text("You are now ready to rent, lend, buy, and sell resources, connect with your community, and make better use of shared resources.", textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 15, height: 1.4, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Force refresh layout/auth state
                    Navigator.of(context).pushReplacementNamed('/');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Go to Home', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Explore Marketplace', style: TextStyle(color: _primaryGreen, fontSize: 16, decoration: TextDecoration.underline, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ],
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStep1Phone(),
                        _buildStep2Account(),
                        _buildStep3Profile(),
                        _buildFinalSuccess(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
