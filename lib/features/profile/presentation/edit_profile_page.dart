import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../localization/app_localizations.dart';
import '../../../models/app_user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/cloudinary_service.dart';
import '../../../widgets/image_loader.dart';
import '../../../services/logger_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    required this.initialUser,
    required this.authService,
  });

  final AppUserModel initialUser;
  final AuthService authService;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();

  final _picker = ImagePicker();
  final _cloudinary = CloudinaryService();

  File? _newImage;
  bool _removePhoto = false;
  bool _saving = false;
  bool _hasEdits = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialUser.name;
    _usernameController.text = widget.initialUser.username ?? '';
    _bioController.text = widget.initialUser.bio ?? '';

    final locationParts = [widget.initialUser.village, widget.initialUser.district, widget.initialUser.state]
        .where((e) => e != null && e.trim().isNotEmpty)
        .toList();
    _locationController.text = locationParts.isNotEmpty ? locationParts.first : '';

    _nameController.addListener(_onEdit);
    _usernameController.addListener(_onEdit);
    _locationController.addListener(_onEdit);
    _bioController.addListener(_onEdit);
  }

  void _onEdit() {
    if (!_hasEdits) {
      setState(() => _hasEdits = true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _locationController.dispose();
    _bioController.dispose();
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
      if (picked == null) return;

      setState(() {
        _newImage = File(picked.path);
        _removePhoto = false;
        _hasEdits = true;
      });
    } catch (e) {
      LoggerService.error('Error selecting image', e);
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text('Profile Picture Source', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF2E7D32)),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF2E7D32)),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (widget.initialUser.profileImage.isNotEmpty || _newImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _newImage = null;
                    _removePhoto = true;
                    _hasEdits = true;
                  });
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<bool> _isUsernameUnique(String username) async {
    final normalized = username.trim().toLowerCase();
    if (normalized == widget.initialUser.username?.toLowerCase()) {
      return true;
    }
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: normalized)
        .limit(1)
        .get();
    return query.docs.isEmpty;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
    });

    try {
      final username = _usernameController.text.trim();
      if (username.isNotEmpty) {
        final isUnique = await _isUsernameUnique(username);
        if (!isUnique) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Username is already taken.'), backgroundColor: Colors.red),
            );
          }
          setState(() => _saving = false);
          return;
        }
      }

      var imageUrl = _removePhoto ? '' : widget.initialUser.profileImage;
      if (_newImage != null) {
        final upload = await _cloudinary.uploadImageWithMetadata(_newImage!);
        imageUrl = upload.secureUrl;
      }

      await widget.authService.updateCurrentUserProfile(
        name: _nameController.text.trim(),
        phoneNumber: widget.initialUser.phoneNumber,
        profileImage: imageUrl,
        username: username,
        bio: _bioController.text.trim(),
        village: _locationController.text.trim(),
        district: _locationController.text.trim(),
        state: '',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.tr('profile_updated')),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      LoggerService.error('Error saving profile changes', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.tr('error_occurred')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasEdits) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Discard Changes?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6F7A6B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: !_hasEdits,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAF8),
        appBar: AppBar(
          title: Text(l10n.tr('edit_profile'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E7D32)))
                  : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32), fontSize: 16)),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: const Color(0xFFE8F5E9),
                      child: ClipOval(
                        child: _removePhoto
                            ? const Icon(Icons.person, size: 42, color: Color(0xFF2E7D32))
                            : _newImage != null
                                ? Image.file(_newImage!, width: 96, height: 96, fit: BoxFit.cover)
                                : widget.initialUser.profileImage.trim().isNotEmpty
                                    ? buildSmartImage(
                                        widget.initialUser.profileImage,
                                        width: 96,
                                        height: 96,
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(Icons.person, size: 42, color: Color(0xFF2E7D32)),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: InkWell(
                        onTap: _showImageSourceDialog,
                        child: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xFF2E7D32),
                          child: Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _showImageSourceDialog,
                  child: const Text('Change Photo', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Full name is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixText: '@',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null; // optional or allow empty to clean it
                  }
                  final val = value.trim();
                  final validChars = RegExp(r'^[a-zA-Z0-9_]+$');
                  if (!validChars.hasMatch(val)) {
                    return 'Only letters, numbers, and underscores are allowed.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Approximate Location (e.g. Chennai)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Location is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                maxLength: 150,
                decoration: InputDecoration(
                  labelText: 'Short Bio (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2)),
                ),
                validator: (value) {
                  if (value != null && value.trim().length > 150) {
                    return 'Bio cannot exceed 150 characters.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
