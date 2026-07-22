import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pinput/pinput.dart';
import 'dart:ui';
import '../../../models/app_user_model.dart';
import '../../../services/auth_service.dart';
import 'package:UzhavuSei/theme/app_theme.dart';
import '../../../config/categories_config.dart';
import '../../../services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationFlowPage extends StatefulWidget {
  const RegistrationFlowPage({super.key, required this.authService});
  final AuthService authService;

  @override
  State<RegistrationFlowPage> createState() => _RegistrationFlowPageState();
}

class _RegistrationFlowPageState extends State<RegistrationFlowPage> with TickerProviderStateMixin, WidgetsBindingObserver {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _phoneVerified = true;
      if (user.email != null && user.email!.isNotEmpty) {
        _currentPage = 2;
      } else {
        _currentPage = 1;
      }
    } else {
      _currentPage = 0;
      _phoneVerified = false;
    }
    
    _pageController = PageController(initialPage: _currentPage);
    _initializeLocation();
  }

  // -- Colors
  final Color _primaryGreen = AppColors.primary;
  final Color _darkGreen = AppColors.primary;
  final Color _lightGreen = AppColors.primaryContainer;
  
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
  final _stateController = TextEditingController();
  String? _selectedState;
  
  final List<String> _selectedPurposes = [];
  final List<String> _selectedInterests = [];
  final List<String> _selectedShareCategories = [];

  final Map<String, bool> _notifications = {
    'nearbyListings': true,
    'borrowRequests': true,
    'returnReminders': true,
  };

  bool _fetchingLocation = false;
  VerifiedLocation? _gpsLocation;
  String? _locationError;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndFetchLocationSilently();
    }
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
    int total = 3;
    int filled = 0;
    if (_selectedState != null && _selectedState!.isNotEmpty) filled++;
    if (_gpsLocation != null) filled++;
    if (_selectedInterests.isNotEmpty) filled++;
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

  LocationPermissionStatus _permissionStatus = LocationPermissionStatus.unknown;

  void _updateLocationErrorStatus(LocationPermissionStatus status) {
    switch (status) {
      case LocationPermissionStatus.serviceDisabled:
        _locationError = 'GPS is disabled. Please enable location services.';
        break;
      case LocationPermissionStatus.denied:
        _locationError = 'Location permission is denied.';
        break;
      case LocationPermissionStatus.permanentlyDenied:
        _locationError = 'Location permission is permanently denied. Please enable it in Settings.';
        break;
      default:
        _locationError = 'Location service status unknown.';
    }
  }

  Future<void> _initializeLocation() async {
    setState(() {
      _fetchingLocation = true;
      _locationError = null;
    });
    
    VerifiedLocation? cached;
    try {
      cached = await LocationService.instance.getLastVerifiedLocation();
      final loc = cached;
      if (loc != null) {
        setState(() {
          _gpsLocation = loc;
        });
      }
      
      final prefs = await SharedPreferences.getInstance();
      final stateCached = prefs.getString('lvl_state');
      if (stateCached != null) {
        setState(() {
          _selectedState = stateCached;
          _stateController.text = stateCached;
        });
      }
    } catch (e) {
      debugPrint('[RegistrationFlow] Error loading cached location: $e');
    }

    await _fetchGpsLocation(isBackground: cached != null);
  }

  Future<void> _checkAndFetchLocationSilently() async {
    final status = await LocationService.instance.checkPermissionStatus();
    setState(() {
      _permissionStatus = status;
    });

    if (status == LocationPermissionStatus.granted) {
      await _fetchGpsLocation(isBackground: _gpsLocation != null);
    } else {
      setState(() {
        _updateLocationErrorStatus(status);
      });
    }
  }

  Future<void> _fetchGpsLocation({bool isBackground = false}) async {
    if (_fetchingLocation) return;
    if (!isBackground) {
      setState(() {
        _fetchingLocation = true;
        _locationError = null;
      });
    }

    try {
      // 1. Check services
      final serviceEnabled = await LocationService.instance.isLocationServiceEnabled();
      debugPrint('[GPS Log] GPS Enabled check: $serviceEnabled');
      if (!serviceEnabled) {
        setState(() {
          _fetchingLocation = false;
          _locationError = 'GPS is disabled. Please enable location services.';
          _permissionStatus = LocationPermissionStatus.serviceDisabled;
        });
        return;
      }

      // 2. Check permission
      final status = await LocationService.instance.checkPermissionStatus();
      debugPrint('[GPS Log] Permission check status: $status');
      setState(() {
        _permissionStatus = status;
      });

      if (status != LocationPermissionStatus.granted) {
        setState(() {
          _fetchingLocation = false;
          _updateLocationErrorStatus(status);
        });
        return;
      }

      // 3. Request current position (coordinates) with 3 retries
      Position? position;
      String? positionError;
      for (int i = 0; i < 3; i++) {
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 15),
          );
          if (position.accuracy <= 100) {
            break;
          } else {
            positionError = 'Coordinates accuracy is poor: ${position.accuracy} meters.';
          }
        } catch (e) {
          positionError = e.toString();
          debugPrint('[GPS Log] Position retrieval attempt ${i + 1} failed: $e');
          if (i < 2) {
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      }

      if (position == null) {
        throw Exception(positionError ?? 'Could not retrieve GPS coordinates.');
      }

      final lat = position.latitude;
      final lng = position.longitude;
      debugPrint('[GPS Log] Coordinates resolved successfully - Lat: $lat, Lng: $lng, Accuracy: ${position.accuracy}');

      // Save verified location to state and SharedPreferences local cache
      final location = VerifiedLocation(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: position.accuracy,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('lvl_latitude', lat);
      await prefs.setDouble('lvl_longitude', lng);
      await prefs.setInt('lvl_timestamp_ms', DateTime.now().millisecondsSinceEpoch);
      await prefs.setDouble('lvl_accuracy', position.accuracy);

      setState(() {
        _gpsLocation = location;
        _locationError = null;
        _fetchingLocation = false;
      });

    } catch (e) {
      debugPrint('[GPS Log] Fetch GPS Location Error: $e');
      setState(() {
        if (_gpsLocation == null) {
          _locationError = 'Unable to determine your location. Please check your location settings.';
        }
        _fetchingLocation = false;
      });
    }
  }

  Future<void> _onEnableLocationPressed() async {
    final status = await LocationService.instance.checkPermissionStatus();
    if (status == LocationPermissionStatus.serviceDisabled) {
      await LocationService.instance.openLocationSettings();
    } else if (status == LocationPermissionStatus.denied) {
      final newStatus = await LocationService.instance.requestPermission();
      setState(() {
        _permissionStatus = newStatus;
      });
      if (newStatus == LocationPermissionStatus.granted) {
        await _fetchGpsLocation();
      } else {
        setState(() {
          _updateLocationErrorStatus(newStatus);
        });
      }
    } else if (status == LocationPermissionStatus.permanentlyDenied) {
      await LocationService.instance.openAppPermissionSettings();
    } else {
      await _fetchGpsLocation();
    }
  }

  Future<void> _saveProfileAndFinish() async {
    if (!_profileFormKey.currentState!.validate()) return;
    
    if (_selectedState == null || _selectedState!.isEmpty) {
      _showError('Please select your State.');
      return;
    }

    if (_selectedInterests.isEmpty) {
      _showError('Please select at least one Interested Category');
      return;
    }

    if (_gpsLocation == null) {
      _showError('GPS location coordinates are required.');
      return;
    }

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
          role: 'user',
          phoneNumber: phone,
          profileImage: '',
          language: 'en',
          createdAt: DateTime.now(),
          emailVerified: user.emailVerified,
          phoneVerified: true,
          latitude: _gpsLocation!.latitude,
          longitude: _gpsLocation!.longitude,
          selectedState: _selectedState,
          locationUpdatedAt: _gpsLocation!.timestamp,
          accuracy: _gpsLocation!.accuracy,
          preferredCategories: _selectedInterests,
          listingCategories: _selectedShareCategories,
          notificationsEnabled: _notifications,
        );
        
        final dataMap = appUser.toMap();
        dataMap['purposes'] = _selectedPurposes;
        
        await FirebaseFirestore.instance.collection('users').doc(uid).set(dataMap);

        // Also save state to SharedPreferences cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('lvl_state', _selectedState!);

        if (!mounted) return;
        setState(() => _submitting = false);
        _nextPage();
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
    final catOptions = CategoriesConfig.categories.map((c) => c.displayName).toList();
    
    return StatefulBuilder(
      builder: (context, setStateLocal) {
        final locationResolved = _selectedState != null && _selectedState!.isNotEmpty && _gpsLocation != null;
        
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Complete Your\nBorrow Profile", style: TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold, height: 1.2)),
              const SizedBox(height: 8),
              const Text("Help us personalize your Borrow experience", style: TextStyle(color: Colors.black54, fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 20),
              _buildGlassCard(
                child: Form(
                  key: _profileFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- SECTION 1: I WANT TO... ---
                      const Text('I want to...', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Select all that apply to personalize recommendations', style: TextStyle(color: Colors.black54, fontSize: 12)),
                      const SizedBox(height: 12),
                      _buildChipSelector(catOptions, _selectedPurposes, setStateLocal),
                      const SizedBox(height: 24),

                      // --- SECTION 2: STATE SELECTION ---
                      const Text('State / Union Territory', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Select your home state manually (Required)', style: TextStyle(color: Colors.black54, fontSize: 12)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _stateController,
                        readOnly: true,
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                        decoration: _glassInputDecoration('Select State', Icons.map).copyWith(
                          suffixIcon: (_selectedState != null)
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : const Icon(Icons.arrow_drop_down),
                        ),
                        onTap: () => _showStatePicker(setStateLocal),
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'State is required' : null,
                      ),
                      const SizedBox(height: 24),

                      // --- SECTION 3: GPS ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Current Location', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                          if (_fetchingLocation)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _gpsLocation != null ? 'Location Enabled' : 'Location not enabled',
                        style: TextStyle(
                          color: _gpsLocation != null ? Colors.green : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Location Buttons / Errors
                      if (_locationError != null) ...[
                        Text(
                          _locationError!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (_fetchingLocation) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          child: const Text('Acquiring GPS fix...', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                        )
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            icon: Icon(_gpsLocation != null ? Icons.refresh : Icons.location_searching),
                            label: Text(
                              _gpsLocation != null ? 'Refresh Location' : 'Enable Location',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: _primaryGreen),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              if (_gpsLocation != null) {
                                await _fetchGpsLocation();
                              } else {
                                await _onEnableLocationPressed();
                              }
                              setStateLocal(() {});
                            },
                          ),
                        )
                      ],
                      const SizedBox(height: 24),

                      // --- SECTION 4: INTERESTED CATEGORIES ---
                      const Text('Interested Categories', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Choose the categories you are interested in (Required)', style: TextStyle(color: Colors.black54, fontSize: 12)),
                      const SizedBox(height: 12),
                      _buildChipSelector(catOptions, _selectedInterests, setStateLocal),
                      const SizedBox(height: 24),

                      // --- SECTION 5: I CAN LIST... ---
                      const Text('I can list... (Optional)', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Select categories you might want to share or list', style: TextStyle(color: Colors.black54, fontSize: 12)),
                      const SizedBox(height: 12),
                      _buildChipSelector(catOptions, _selectedShareCategories, setStateLocal),
                      const SizedBox(height: 24),

                      // --- SECTION 6: NOTIFICATIONS ---
                      const Text('Notifications', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Material(
                        color: Colors.transparent,
                        clipBehavior: Clip.antiAlias,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            children: [
                              _buildNotificationToggle(
                                'Nearby Listings',
                                'nearbyListings',
                                setStateLocal,
                              ),
                              const Divider(height: 1, indent: 16, endIndent: 16),
                              _buildNotificationToggle(
                                'Borrow Requests',
                                'borrowRequests',
                                setStateLocal,
                              ),
                              const Divider(height: 1, indent: 16, endIndent: 16),
                              _buildNotificationToggle(
                                'Return Reminders',
                                'returnReminders',
                                setStateLocal,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_submitting || !locationResolved) ? null : _saveProfileAndFinish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                  ),
                  child: _submitting 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('Complete Registration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showStatePicker(StateSetter stateSetter) {
    String searchQuery = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = CategoriesConfig.indianStates
                .where((s) => s.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Select State / Union Territory',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search State...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (val) {
                          setModalState(() {
                            searchQuery = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final stateName = filtered[index];
                            final isSelected = _selectedState == stateName;
                            return ListTile(
                              title: Text(
                                stateName,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? _primaryGreen : Colors.black87,
                                ),
                              ),
                              trailing: isSelected ? Icon(Icons.check, color: _primaryGreen) : null,
                              onTap: () {
                                stateSetter(() {
                                  _selectedState = stateName;
                                  _stateController.text = stateName;
                                });
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationToggle(String label, String key, StateSetter stateSetter) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500)),
      value: _notifications[key] ?? true,
      activeColor: Colors.white,
      activeTrackColor: _primaryGreen,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: Colors.grey.shade300,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onChanged: (val) {
        stateSetter(() {
          _notifications[key] = val;
        });
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
