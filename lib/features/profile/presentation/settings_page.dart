import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/app_user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/location_service.dart';
import '../../../services/logger_service.dart';
import 'edit_profile_page.dart';
import 'verification_center_page.dart';
import '../../auth/presentation/login_register_page.dart';
import '../../../Maintenance.dart';
import 'package:UzhavuSei/theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.currentUser,
    required this.authService,
  });

  final AppUserModel currentUser;
  final AuthService authService;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _currentTheme = 'System';
  String _currentLanguage = 'en';

  bool _loading = false;
  AppUserModel? _liveUser;

  @override
  void initState() {
    super.initState();
    _subscribeToUserChanges();
    _loadPreferences();
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

  AppUserModel get _user => _liveUser ?? widget.currentUser;

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentTheme = prefs.getString('theme_preference') ?? 'System';
      _currentLanguage = prefs.getString('language_preference') ?? 'en';
    });
  }

  Future<void> _savePreference(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    _loadPreferences();
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Select Theme', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('System Default'),
              value: 'System',
              groupValue: _currentTheme,
              activeColor: AppColors.primary,
              onChanged: (val) {
                if (val != null) {
                  _savePreference('theme_preference', val);
                  Navigator.pop(ctx);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Light'),
              value: 'Light',
              groupValue: _currentTheme,
              activeColor: AppColors.primary,
              onChanged: (val) {
                if (val != null) {
                  _savePreference('theme_preference', val);
                  Navigator.pop(ctx);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Dark'),
              value: 'Dark',
              groupValue: _currentTheme,
              activeColor: AppColors.primary,
              onChanged: (val) {
                if (val != null) {
                  _savePreference('theme_preference', val);
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Select Language', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: _currentLanguage,
              activeColor: AppColors.primary,
              onChanged: (val) {
                if (val != null) {
                  _savePreference('language_preference', val);
                  Navigator.pop(ctx);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Tamil (தமிழ்)'),
              value: 'ta',
              groupValue: _currentLanguage,
              activeColor: AppColors.primary,
              onChanged: (val) {
                if (val != null) {
                  _savePreference('language_preference', val);
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToUpdateLocation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _UpdateLocationScreen(
          currentUser: _user,
          db: _db,
        ),
      ),
    );
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _NotificationsScreen(
          userId: _user.userId,
          db: _db,
        ),
      ),
    );
  }

  void _navigateToPrivacySettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PrivacyScreen(
          userId: _user.userId,
          db: _db,
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _loading = true);
              try {
                await widget.authService.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => LoginRegisterPage(authService: widget.authService)),
                    (route) => false,
                  );
                }
              } catch (e) {
                LoggerService.error('Error logging out', e);
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final textController = TextEditingController();
    bool deleteEnabled = false;
    String? localError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WARNING: This action is permanent and cannot be undone. All your shared listings, history, and profile data will be deleted forever.',
                  style: TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please type DELETE to confirm account deletion:',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    hintText: 'DELETE',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    errorText: localError,
                  ),
                  onChanged: (val) {
                    setDialogState(() {
                      deleteEnabled = val.trim() == 'DELETE';
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: !deleteEnabled
                    ? null
                    : () async {
                        setDialogState(() => _loading = true);
                        try {
                          final user = _auth.currentUser;
                          if (user != null) {
                            final uid = user.uid;
                            await _db.collection('users').doc(uid).delete();
                            await user.delete();
                          }
                          if (mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => LoginRegisterPage(authService: widget.authService)),
                              (route) => false,
                            );
                          }
                        } catch (e) {
                          LoggerService.error('Error deleting account', e);
                          setDialogState(() {
                            _loading = false;
                            localError = 'Failed to delete account. Try logging in again first.';
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: _loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Confirm Delete'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              // 1. ACCOUNT
              _buildSectionHeader('ACCOUNT'),
              _buildSettingsCard([
                _buildSettingsTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Edit Profile',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfilePage(
                          initialUser: _user,
                          authService: widget.authService,
                        ),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.verified_outlined,
                  title: 'Verification',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VerificationCenterPage(
                          currentUser: _user,
                          authService: widget.authService,
                        ),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.location_on_outlined,
                  title: 'Update Location',
                  onTap: _navigateToUpdateLocation,
                ),
              ]),

              const SizedBox(height: 24),

              // 2. PREFERENCES
              _buildSectionHeader('PREFERENCES'),
              _buildSettingsCard([
                _buildSettingsTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  onTap: _navigateToNotifications,
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.language_rounded,
                  title: 'Language',
                  trailing: Text(
                    _currentLanguage == 'en' ? 'English' : 'Tamil (தமிழ்)',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  onTap: _showLanguageDialog,
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Theme',
                  trailing: Text(
                    _currentTheme,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  onTap: _showThemeDialog,
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Privacy Settings',
                  onTap: _navigateToPrivacySettings,
                ),
              ]),

              const SizedBox(height: 24),

              // 3. SUPPORT
              _buildSectionHeader('SUPPORT'),
              _buildSettingsCard([
                _buildSettingsTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MaintenancePage()));
                  },
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const _PrivacyPolicyScreen()));
                  },
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.description_outlined,
                  title: 'Terms & Conditions',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const _TermsScreen()));
                  },
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About Borrow',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const _AboutScreen()));
                  },
                ),
              ]),

              const SizedBox(height: 24),

              // 4. ACCOUNT ACTIONS
              _buildSectionHeader('ACCOUNT ACTIONS'),
              _buildSettingsCard([
                _buildSettingsTile(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  titleColor: AppColors.primary,
                  iconColor: AppColors.primary,
                  onTap: _showLogoutDialog,
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.delete_forever_rounded,
                  title: 'Delete Account',
                  titleColor: Colors.red,
                  iconColor: Colors.red,
                  onTap: _showDeleteAccountDialog,
                ),
              ]),
            ],
          ),
          if (_loading)
            Container(
              color: Colors.black.withValues(alpha: 0.1),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEFF0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    Color? titleColor,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? const Color(0xFF3F4A3C), size: 22),
      title: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: titleColor ?? AppColors.textPrimary),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: Color(0xFFEBEFF0));
  }
}

// ── SUB-SCREENS ──────────────────────────────────────────────────────────────

class _UpdateLocationScreen extends StatefulWidget {
  const _UpdateLocationScreen({required this.currentUser, required this.db});
  final AppUserModel currentUser;
  final FirebaseFirestore db;

  @override
  State<_UpdateLocationScreen> createState() => _UpdateLocationScreenState();
}

class _UpdateLocationScreenState extends State<_UpdateLocationScreen> {
  bool _loading = false;
  String? _city;
  String? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _city = widget.currentUser.selectedState;
    _lastUpdated = 'Just now';
  }

  Future<void> _refreshLocation() async {
    setState(() => _loading = true);
    try {
      final result = await LocationService.instance.getCurrentLocation();
      if (result is LocationSuccess) {
        final loc = result.location;
        await widget.db.collection('users').doc(widget.currentUser.userId).update({
          'latitude': loc.latitude,
          'longitude': loc.longitude,
          'locationUpdatedAt': FieldValue.serverTimestamp(),
          'accuracy': loc.accuracy ?? 0.0,
        });
        setState(() {
          _lastUpdated = 'Updated just now';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location updated successfully!'), backgroundColor: AppColors.primary),
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
      LoggerService.error('Error updating location', e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Update Location')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEBEFF0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 48),
              const SizedBox(height: 16),
              const Text('Verified Location Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Text('Current State: ${_city ?? 'Not Set'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text('Last Updated: ${_lastUpdated ?? 'Unknown'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _refreshLocation,
                  icon: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.refresh, color: Colors.white),
                  label: const Text('Refresh Location', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationsScreen extends StatefulWidget {
  const _NotificationsScreen({required this.userId, required this.db});
  final String userId;
  final FirebaseFirestore db;

  @override
  State<_NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<_NotificationsScreen> {
  bool _requests = true;
  bool _chat = true;
  bool _updates = true;
  bool _announcements = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final doc = await widget.db.collection('users').doc(widget.userId).get();
    if (doc.exists && doc.data()?['notificationSettings'] != null) {
      final data = doc.data()?['notificationSettings'] as Map;
      setState(() {
        _requests = data['requests'] ?? true;
        _chat = data['chat'] ?? true;
        _updates = data['updates'] ?? true;
        _announcements = data['announcements'] ?? false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    try {
      await widget.db.collection('users').doc(widget.userId).set({
        'notificationSettings': {
          'requests': _requests,
          'chat': _chat,
          'updates': _updates,
          'announcements': _announcements,
        }
      }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences saved successfully!'), backgroundColor: AppColors.primary),
        );
      }
    } catch (e) {
      LoggerService.error('Error saving notification preferences', e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEBEFF0)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Borrow Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Get notified when someone requests your items', style: TextStyle(fontSize: 12)),
                  value: _requests,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _requests = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Chat Messages', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Get notified when you receive new chat messages', style: TextStyle(fontSize: 12)),
                  value: _chat,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _chat = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Item Updates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Get notified of changes to status of borrow requests', style: TextStyle(fontSize: 12)),
                  value: _updates,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _updates = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('General Announcements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Stay updated with community events and features', style: TextStyle(fontSize: 12)),
                  value: _announcements,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _announcements = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyScreen extends StatefulWidget {
  const _PrivacyScreen({required this.userId, required this.db});
  final String userId;
  final FirebaseFirestore db;

  @override
  State<_PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<_PrivacyScreen> {
  bool _showApproxLoc = true;
  bool _allowDms = true;
  bool _receiveRequests = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    final doc = await widget.db.collection('users').doc(widget.userId).get();
    if (doc.exists && doc.data()?['privacySettings'] != null) {
      final data = doc.data()?['privacySettings'] as Map;
      setState(() {
        _showApproxLoc = data['showApproxLoc'] ?? true;
        _allowDms = data['allowDms'] ?? true;
        _receiveRequests = data['receiveRequests'] ?? true;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    try {
      await widget.db.collection('users').doc(widget.userId).set({
        'privacySettings': {
          'showApproxLoc': _showApproxLoc,
          'allowDms': _allowDms,
          'receiveRequests': _receiveRequests,
        }
      }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Privacy settings updated!'), backgroundColor: AppColors.primary),
        );
      }
    } catch (e) {
      LoggerService.error('Error saving privacy preferences', e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Privacy Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEBEFF0)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Show Approximate Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Allow other users to see your approximate town/city', style: TextStyle(fontSize: 12)),
                  value: _showApproxLoc,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _showApproxLoc = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Allow Direct Messages', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Allow direct chat requests from other members', style: TextStyle(fontSize: 12)),
                  value: _allowDms,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _allowDms = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Receive Borrow Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Show your items as requestable in search grids', style: TextStyle(fontSize: 12)),
                  value: _receiveRequests,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _receiveRequests = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Settings', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyPolicyScreen extends StatelessWidget {
  const _PrivacyPolicyScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            SizedBox(height: 16),
            Text(
              'Your privacy is extremely important to us. Borrow does not collect or share exact location details before exchange approval. Only approximate distances and state details are shown to other users to discover resources.',
              style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
            ),
            SizedBox(height: 16),
            Text('Data Security', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            Text(
              'All user contact details and exact addresses are kept confidential on secure Firestore nodes and only shared with approved exchangers.',
              style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsScreen extends StatelessWidget {
  const _TermsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Terms & Conditions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            SizedBox(height: 16),
            Text(
              'Welcome to Borrow. By using our platform, you agree to comply with and be bound by the following terms of use.',
              style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
            ),
            SizedBox(height: 16),
            Text('Exchanges & Accountability', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            Text(
              'Borrow is a free community platform. Users are fully responsible for the items they lend and borrow, ensuring proper upkeep and prompt return in their original condition.',
              style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutScreen extends StatelessWidget {
  const _AboutScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('About Borrow')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.loop_rounded, color: AppColors.primary, size: 64),
              SizedBox(height: 16),
              Text('Borrow', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
              SizedBox(height: 6),
              Text('Version 1.0.0 (Build 1)', style: TextStyle(color: Colors.grey, fontSize: 14)),
              SizedBox(height: 16),
              Text(
                'Community Resource Sharing Platform',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              SizedBox(height: 24),
              Divider(),
              SizedBox(height: 16),
              Text('Contact Support: support@borrow.com', style: TextStyle(fontSize: 13, color: Colors.black87)),
              SizedBox(height: 4),
              Text('Copyright © 2026 Borrow. All rights reserved.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
