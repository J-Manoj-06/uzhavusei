import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../localization/app_localizations.dart';
import '../../../models/app_user_model.dart';
import '../../../services/auth_service.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({
    super.key,
    required this.initialUser,
    required this.authService,
  });

  final AppUserModel initialUser;
  final AuthService authService;

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  
  // Personal & Contact
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Location
  final _stateController = TextEditingController();
  final _districtController = TextEditingController();
  final _villageController = TextEditingController();
  
  // Agricultural
  final _landAreaController = TextEditingController();
  final _primaryCropsController = TextEditingController();
  final _serviceRangeController = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialUser.name;
    _phoneController.text = widget.initialUser.phoneNumber;
    
    _stateController.text = widget.initialUser.state ?? '';
    _districtController.text = widget.initialUser.district ?? '';
    _villageController.text = widget.initialUser.village ?? '';
    
    _landAreaController.text = widget.initialUser.landArea ?? '';
    _primaryCropsController.text = widget.initialUser.primaryCrops ?? '';
    _serviceRangeController.text = widget.initialUser.serviceRange ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _villageController.dispose();
    _landAreaController.dispose();
    _primaryCropsController.dispose();
    _serviceRangeController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await widget.authService.updateAdvancedUserProfile(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        state: _stateController.text.trim(),
        district: _districtController.text.trim(),
        village: _villageController.text.trim(),
        landArea: _landAreaController.text.trim(),
        primaryCrops: _primaryCropsController.text.trim(),
        serviceRange: _serviceRangeController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile completed successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while saving.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: Colors.white.withValues(alpha: 0.7),
              elevation: 0,
              iconTheme: const IconThemeData(color: Color(0xFF006E1C)),
              title: const Text(
                'Complete Profile',
                style: TextStyle(
                  color: Color(0xFF191C1C),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionHeader(Icons.person, 'Personal Information'),
              _buildCard([
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.badge,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ]),
              const SizedBox(height: 24),

              _buildSectionHeader(Icons.location_on, 'Location Details'),
              _buildCard([
                _buildTextField(
                  controller: _stateController,
                  label: 'State',
                  icon: Icons.map,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _districtController,
                  label: 'District',
                  icon: Icons.location_city,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _villageController,
                  label: 'Village / Town',
                  icon: Icons.home,
                ),
              ]),
              const SizedBox(height: 24),

              _buildSectionHeader(Icons.eco, 'Agricultural Profile'),
              _buildCard([
                _buildTextField(
                  controller: _landAreaController,
                  label: 'Land Area (e.g. 5 Acres)',
                  icon: Icons.landscape,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _primaryCropsController,
                  label: 'Primary Crops (e.g. Paddy, Sugarcane)',
                  icon: Icons.grass,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _serviceRangeController,
                  label: 'Service Radius (km)',
                  icon: Icons.radar,
                  keyboardType: TextInputType.number,
                ),
              ]),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _saving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006E1C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Save Profile',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF006E1C), size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3F4A3C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFBECAB9).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6F7A6B)),
        filled: true,
        fillColor: const Color(0xFFF9F9F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFFBECAB9).withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF006E1C), width: 1.5),
        ),
      ),
    );
  }
}
