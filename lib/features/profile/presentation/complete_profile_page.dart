import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/app_user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/cloudinary_service.dart';
import '../../../widgets/image_loader.dart';
import 'package:UzhavuSei/theme/app_theme.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({
    super.key,
    required this.authService,
    this.initialUser,
    this.isMandatory = true,
  });

  final AuthService authService;
  final AppUserModel? initialUser;
  final bool isMandatory;

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _regNoController;
  late final TextEditingController _collegeEmailController;
  late final TextEditingController _phoneController;

  String? _selectedDepartment;
  String? _selectedYear;

  File? _newPhoto;
  bool _isSaving = false;
  String? _regNoErrorMessage;

  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinary = CloudinaryService();

  static const List<String> _departments = [
    'Computer Science',
    'Information Technology',
    'Artificial Intelligence & Data Science',
    'Electronics & Communication',
    'Electrical & Electronics',
    'Mechanical',
    'Civil',
    'Biomedical',
    'MBA',
    'MCA',
    'Others',
  ];

  static const List<String> _years = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    'Postgraduate',
  ];

  @override
  void initState() {
    super.initState();
    final user = widget.initialUser;
    final firebaseUser = FirebaseAuth.instance.currentUser;

    _fullNameController = TextEditingController(
      text: user?.fullName ?? firebaseUser?.displayName ?? '',
    );
    _regNoController = TextEditingController(
      text: user?.registerNumber ?? '',
    );
    _collegeEmailController = TextEditingController(
      text: user?.collegeEmail.isNotEmpty == true
          ? user!.collegeEmail
          : (firebaseUser?.email ?? ''),
    );
    _phoneController = TextEditingController(
      text: user?.phone.isNotEmpty == true
          ? user!.phone
          : (firebaseUser?.phoneNumber ?? ''),
    );

    if (user != null && _departments.contains(user.department)) {
      _selectedDepartment = user.department;
    }
    if (user != null && _years.contains(user.year)) {
      _selectedYear = user.year;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _regNoController.dispose();
    _collegeEmailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _newPhoto = File(picked.path));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to select image.')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Profile Photo (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<bool> _checkRegisterNumberUniqueness(String regNo) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final cleaned = regNo.trim();
    if (cleaned.isEmpty) return false;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('registerNumber', isEqualTo: cleaned)
          .get();

      for (final doc in snapshot.docs) {
        if (doc.id != uid) {
          return false; // Taken by another user
        }
      }
      return true;
    } catch (_) {
      return true; // Allow proceed if index error occurs
    }
  }

  Future<void> _submitProfile() async {
    setState(() => _regNoErrorMessage = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);

    try {
      final regNo = _regNoController.text.trim();
      final isUnique = await _checkRegisterNumberUniqueness(regNo);

      if (!isUnique) {
        setState(() {
          _isSaving = false;
          _regNoErrorMessage = 'This Register Number is already registered.';
        });
        _formKey.currentState!.validate();
        return;
      }

      String photoUrl = widget.initialUser?.photoUrl ?? '';
      if (_newPhoto != null) {
        final upload = await _cloudinary.uploadImageWithMetadata(_newPhoto!);
        photoUrl = upload.secureUrl;
      }

      final fullName = _fullNameController.text.trim();
      final collegeEmail = _collegeEmailController.text.trim();
      final phone = _phoneController.text.trim();

      // Save to users/{uid} in Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'userId': uid,
        'fullName': fullName,
        'name': fullName,
        'registerNumber': regNo,
        'department': _selectedDepartment,
        'year': _selectedYear,
        'collegeEmail': collegeEmail,
        'email': collegeEmail,
        'phone': phone,
        'phoneNumber': phone,
        'photoUrl': photoUrl,
        'profileImage': photoUrl,
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile completed successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      if (widget.isMandatory) {
        // Force refresh / replace route to Home
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isMandatory,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            'Complete Student Profile',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: !widget.isMandatory,
          actions: [
            if (widget.isMandatory)
              IconButton(
                tooltip: 'Sign Out',
                icon: const Icon(Icons.logout_rounded, color: Colors.red),
                onPressed: () => widget.authService.signOut(),
              ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.school_rounded, size: 36, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Student Profile Required',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Please provide your academic details to request and borrow library books.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Profile Photo Picker (Optional)
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 46,
                              backgroundColor: AppColors.primaryContainer,
                              child: _newPhoto != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(46),
                                      child: Image.file(_newPhoto!, width: 92, height: 92, fit: BoxFit.cover),
                                    )
                                  : (widget.initialUser?.photoUrl.isNotEmpty == true
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(46),
                                          child: buildSmartImage(
                                            widget.initialUser!.photoUrl,
                                            width: 92,
                                            height: 92,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Icon(Icons.person_rounded, size: 48, color: AppColors.primary)),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _showImageSourceDialog,
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.primary,
                                  child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Profile Photo (Optional)',
                          style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 1. Full Name *
                  _buildLabel('Full Name *'),
                  TextFormField(
                    controller: _fullNameController,
                    decoration: _buildInputDecoration(
                      hint: 'Enter your full name',
                      icon: Icons.person_outline_rounded,
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Full Name is required.';
                      }
                      if (v.trim().length < 2) {
                        return 'Enter a valid name.';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // 2. College Register Number *
                  _buildLabel('College Register Number *'),
                  TextFormField(
                    controller: _regNoController,
                    decoration: _buildInputDecoration(
                      hint: 'e.g. 714021104001',
                      icon: Icons.badge_outlined,
                      errorText: _regNoErrorMessage,
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'College Register Number is required.';
                      }
                      if (_regNoErrorMessage != null) {
                        return _regNoErrorMessage;
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // 3. Department *
                  _buildLabel('Department *'),
                  DropdownButtonFormField<String>(
                    value: _selectedDepartment,
                    decoration: _buildInputDecoration(
                      hint: 'Select your department',
                      icon: Icons.account_tree_outlined,
                    ),
                    items: _departments
                        .map((dept) => DropdownMenuItem(
                              value: dept,
                              child: Text(dept, style: const TextStyle(fontSize: 14)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedDepartment = v),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Please select your department.';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // 4. Year of Study *
                  _buildLabel('Year of Study *'),
                  DropdownButtonFormField<String>(
                    value: _selectedYear,
                    decoration: _buildInputDecoration(
                      hint: 'Select year of study',
                      icon: Icons.calendar_today_outlined,
                    ),
                    items: _years
                        .map((yr) => DropdownMenuItem(
                              value: yr,
                              child: Text(yr, style: const TextStyle(fontSize: 14)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedYear = v),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Please select your year of study.';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // 5. College Email *
                  _buildLabel('College Email *'),
                  TextFormField(
                    controller: _collegeEmailController,
                    decoration: _buildInputDecoration(
                      hint: 'student@college.edu',
                      icon: Icons.email_outlined,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'College Email is required.';
                      }
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(v.trim())) {
                        return 'Enter a valid email address.';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // 6. Mobile Number *
                  _buildLabel('Mobile Number *'),
                  TextFormField(
                    controller: _phoneController,
                    decoration: _buildInputDecoration(
                      hint: '10-digit mobile number',
                      icon: Icons.phone_android_outlined,
                    ),
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Mobile Number is required.';
                      }
                      final cleaned = v.trim().replaceAll(RegExp(r'\D'), '');
                      if (cleaned.length != 10) {
                        return 'Mobile Number must be exactly 10 digits.';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 28),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submitProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      child: _isSaving
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Saving Profile...',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            )
                          : const Text(
                              'Save & Continue',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      counterText: '',
    );
  }
}
