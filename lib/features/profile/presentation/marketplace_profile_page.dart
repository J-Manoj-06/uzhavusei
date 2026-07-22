import 'dart:async';
import 'package:flutter/material.dart';

import '../../../localization/app_localizations.dart';
import '../../../models/app_user_model.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/image_loader.dart';
import 'edit_profile_page.dart';
import 'my_bookings_page.dart';
import 'my_equipments_page.dart';
import '../../../services/marketplace_service.dart';
import '../../../models/marketplace_equipment_model.dart';
import '../../../models/marketplace_booking_model.dart';
import '../../../services/logger_service.dart';
import 'verification_center_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'borrow_history_page.dart';
import 'saved_items_page.dart';
import 'settings_page.dart';
import '../data/profile_service.dart';
import 'dart:io';
import 'package:UzhavuSei/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../../providers/location_provider.dart';
import '../../../config/categories_config.dart';
import '../../../services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MarketplaceProfilePage extends StatefulWidget {
  const MarketplaceProfilePage({
    super.key,
    required this.currentUser,
    required this.authService,
  });

  final AppUserModel currentUser;
  final AuthService authService;

  @override
  State<MarketplaceProfilePage> createState() => _MarketplaceProfilePageState();
}

class _MarketplaceProfilePageState extends State<MarketplaceProfilePage> with WidgetsBindingObserver {
  StreamSubscription? _profileSub;

  List<MarketplaceEquipmentModel>? _equipments;
  List<MarketplaceBookingModel>? _userBookings;
  List<MarketplaceBookingModel>? _ownerBookings;
  List<MarketplaceEquipmentModel>? _savedEquipments;
  AppUserModel? _liveUser;

  bool _loadingStats = true;
  bool _errorStats = false;
  bool _isOffline = false;

  bool _fetchingLocation = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkOffline();
    _loadStats();
  }

  void _checkOffline() async {
    try {
      final result = await InternetAddress.lookup('example.com').timeout(const Duration(seconds: 3));
      final offline = result.isEmpty || result[0].rawAddress.isEmpty;
      if (mounted && _isOffline != offline) {
        setState(() {
          _isOffline = offline;
        });
      }
    } catch (_) {
      if (mounted && !_isOffline) {
        setState(() {
          _isOffline = true;
        });
      }
    }
  }

  void _cancelSubscriptions() {
    _profileSub?.cancel();
  }

  void _loadStats() {
    setState(() {
      _loadingStats = true;
      _errorStats = false;
    });

    _cancelSubscriptions();
    _checkOffline();

    try {
      final user = widget.currentUser;

      _profileSub = ProfileService.instance.watchProfileData(user.userId).listen(
        (data) {
          if (!mounted) return;
          setState(() {
            _liveUser = data.user;
            _equipments = data.equipments;
            _userBookings = data.userBookings;
            _ownerBookings = data.ownerBookings;
            _savedEquipments = data.savedEquipments;
            _loadingStats = false;
            _isOffline = false; // Successfully fetched Firestore live streams
          });
        },
        onError: (err) {
          LoggerService.error('Error loading centralized profile data', err);
          setState(() {
            _errorStats = true;
            _loadingStats = false;
          });
        },
      );
    } catch (e) {
      LoggerService.error('Error setting up combined profile streams', e);
      setState(() {
        _errorStats = true;
        _loadingStats = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelSubscriptions();
    super.dispose();
  }

  void _showReviewsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ratings & Reviews', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    _getAverageRating() == 0.0 ? 'New Member' : '${_getAverageRating().toStringAsFixed(1)} / 5.0',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 12),
                  const Text('(Community Feedback)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 10),
              ListTile(
                leading: CircleAvatar(backgroundColor: AppColors.successContainer, child: const Text('A')),
                title: const Text('Anitha R.'),
                subtitle: const Text('Very helpful lender, the shared resource was in excellent condition.'),
                trailing: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(Icons.star, color: Colors.amber, size: 14), Text('5.0')],
                ),
              ),
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.blue[50], child: const Text('M')),
                title: const Text('Manoj K.'),
                subtitle: const Text('Lent me a textbook, process was very smooth and friendly.'),
                trailing: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(Icons.star, color: Colors.amber, size: 14), Text('5.0')],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  double _getAverageRating() {
    if (_equipments == null || _equipments!.isEmpty) return 0.0;
    final ratedItems = _equipments!.where((e) => e.rating > 0).toList();
    if (ratedItems.isEmpty) return 0.0;
    final sum = ratedItems.map((e) => e.rating).reduce((a, b) => a + b);
    return sum / ratedItems.length;
  }

  @override
  Widget _buildFadeIn({required Widget child, int delayMs = 0}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + delayMs),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 15 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _liveUser ?? widget.currentUser;

    // Formatted location
    final displayLoc = (user.selectedState != null && user.selectedState!.isNotEmpty)
        ? '📍 ${user.selectedState}'
        : '📍 Location not set';

    // Username
    final displayUsername = user.username != null && user.username!.trim().isNotEmpty
        ? '@${user.username!.trim().replaceAll('@', '')}'
        : 'Add username';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 30),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsPage(
                    currentUser: user,
                    authService: widget.authService,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          if (_isOffline)
            Container(
              color: Colors.amber.shade800,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Offline Mode • Showing Cached Data',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _loadStats();
                await Future.delayed(const Duration(milliseconds: 600));
              },
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _errorStats
                      ? _buildErrorView()
                      : _loadingStats
                          ? _buildFullPageSkeleton()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 16),
                                
                                // Large Profile Photo
                                _buildFadeIn(
                                  delayMs: 0,
                                  child: Center(
                                    child: CircleAvatar(
                                      radius: 60,
                                      backgroundColor: AppColors.primaryContainer,
                                      child: user.profileImage.trim().isNotEmpty
                                          ? ClipOval(
                                              child: buildSmartImage(
                                                user.profileImage,
                                                width: 120,
                                                height: 120,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : const Icon(Icons.person, size: 60, color: AppColors.primary),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Full Name
                                _buildFadeIn(
                                  delayMs: 50,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        user.name.isEmpty || user.name == 'User' ? 'Complete your profile' : user.name,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      if (_getVerificationCount(user) == 3)
                                        const Icon(Icons.verified, color: Colors.blue, size: 20),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Username
                                _buildFadeIn(
                                  delayMs: 100,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditProfilePage(
                                            initialUser: user,
                                            authService: widget.authService,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      displayUsername,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: user.username != null && user.username!.isNotEmpty
                                            ? Colors.grey.shade600
                                            : AppColors.primary,
                                        fontWeight: user.username != null && user.username!.isNotEmpty
                                            ? FontWeight.normal
                                            : FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Approximate Location
                                _buildFadeIn(
                                  delayMs: 120,
                                  child: Text(
                                    displayLoc,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Member Since
                                _buildFadeIn(
                                  delayMs: 140,
                                  child: Text(
                                    'Member since ${user.createdAt.year}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Optional Short Bio
                                if (user.bio != null && user.bio!.trim().isNotEmpty) ...[
                                  _buildFadeIn(
                                    delayMs: 160,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFFEBEFF0)),
                                      ),
                                      child: Text(
                                        user.bio!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade800,
                                          height: 1.4,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],

                                // Edit Profile Button
                                _buildFadeIn(
                                  delayMs: 180,
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EditProfilePage(
                                              initialUser: user,
                                              authService: widget.authService,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                                      label: const Text(
                                        'Edit Profile',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Verification Center Access Card
                                _buildFadeIn(
                                  delayMs: 200,
                                  child: _buildVerificationSection(user),
                                ),

                                const SizedBox(height: 24),

                                // Location Management Section
                                _buildFadeIn(
                                  delayMs: 210,
                                  child: _buildLocationManagementSection(user),
                                ),

                                const SizedBox(height: 32),

                                // Statistics Grid Section
                                _buildFadeIn(
                                  delayMs: 220,
                                  child: const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Activity Statistics',
                                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                _buildFadeIn(
                                  delayMs: 240,
                                  child: _buildStatsDashboard(user),
                                ),

                                const SizedBox(height: 32),

                                // Activity Section Header
                                _buildFadeIn(
                                  delayMs: 260,
                                  child: const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Activity',
                                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                _buildFadeIn(
                                  delayMs: 280,
                                  child: _buildActivityTiles(user),
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

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Unable to load profile',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'We had trouble fetching your latest profile information. Please verify your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _loadStats,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
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
    );
  }

  Widget _buildFullPageSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
        ),
        const SizedBox(height: 20),
        Container(
          width: 160,
          height: 24,
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
        ),
        const SizedBox(height: 8),
        Container(
          width: 100,
          height: 16,
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6)),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          height: 72,
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
        ),
        const SizedBox(height: 32),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 120,
            height: 20,
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6)),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _buildSkeletonCard(),
            _buildSkeletonCard(),
            _buildSkeletonCard(),
            _buildSkeletonCard(),
          ],
        ),
        const SizedBox(height: 32),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 80,
            height: 20,
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6)),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEBEFF0)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildActivitySkeletonTile(),
              _buildActivitySkeletonTile(),
              _buildActivitySkeletonTile(),
              _buildActivitySkeletonTile(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTiles(AppUserModel user) {
    if (_loadingStats) {
      return Column(
        children: [
          _buildActivitySkeletonTile(),
          _buildActivitySkeletonTile(),
          _buildActivitySkeletonTile(),
          _buildActivitySkeletonTile(),
        ],
      );
    }

    final sharedCount = _equipments!.where((e) => e.status == 'published' || e.status == 'available').length;
    final pendingCount = _userBookings!.where((b) => b.status == 'pending').length;
    final completedCount = _userBookings!.where((b) => b.status == 'completed').length +
        _ownerBookings!.where((b) => b.status == 'completed').length;
    final savedCount = _savedEquipments!.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEFF0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildActivityTile(
            icon: '📦',
            title: 'My Shared Items',
            subtitle: '$sharedCount Active',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MyEquipmentsPage(currentUser: user)),
              );
            },
          ),
          const Divider(height: 1, color: Color(0xFFEBEFF0)),
          _buildActivityTile(
            icon: '📥',
            title: 'My Borrow Requests',
            subtitle: '$pendingCount Pending',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MyBookingsPage(currentUser: user)),
              );
            },
            badgeCount: pendingCount,
          ),
          const Divider(height: 1, color: Color(0xFFEBEFF0)),
          _buildActivityTile(
            icon: '📜',
            title: 'Borrow History',
            subtitle: '$completedCount Exchanges',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BorrowHistoryPage(currentUser: user)),
              );
            },
          ),
          const Divider(height: 1, color: Color(0xFFEBEFF0)),
          _buildActivityTile(
            icon: '❤️',
            title: 'Saved Items',
            subtitle: '$savedCount Items',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SavedItemsPage(currentUser: user)),
              );
            },
            badgeCount: savedCount,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return Material(
      color: Colors.white,
      child: ListTile(
        leading: Text(icon, style: const TextStyle(fontSize: 22)),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeCount > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFC62828), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildActivitySkeletonTile() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 120, height: 14, color: Colors.grey[100]),
                const SizedBox(height: 6),
                Container(width: 60, height: 10, color: Colors.grey[100]),
              ],
            ),
          ),
          Container(width: 16, height: 16, color: Colors.grey[100]),
        ],
      ),
    );
  }

  int _getVerificationCount(AppUserModel user) {
    int count = 0;
    if (user.phoneVerified) count++;
    if ((FirebaseAuth.instance.currentUser?.emailVerified ?? false) || user.emailVerified) count++;
    if (user.latitude != null && user.longitude != null && user.latitude != 0.0 && user.longitude != 0.0) count++;
    return count;
  }

  Widget _buildVerificationSection(AppUserModel user) {
    final count = _getVerificationCount(user);
    final allVerified = count == 3;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerificationCenterPage(
              currentUser: user,
              authService: widget.authService,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEBEFF0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              allVerified ? Icons.verified : Icons.verified_user_outlined,
              color: allVerified ? AppColors.primary : Colors.amber,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Profile Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    allVerified
                        ? "🎉 You're fully verified. Your Borrow profile is ready."
                        : '$count / 3 Verified. Complete verification to build trust.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsDashboard(AppUserModel user) {
    if (_errorStats) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text(
              'Unable to load statistics.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadStats,
              icon: const Icon(Icons.refresh, color: Colors.red),
              label: const Text('Retry', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }

    if (_loadingStats) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
        children: [
          _buildSkeletonCard(),
          _buildSkeletonCard(),
          _buildSkeletonCard(),
          _buildSkeletonCard(),
        ],
      );
    }

    // Live Aggregation calculations
    final sharedCount = _equipments!.where((e) => e.status == 'published' || e.status == 'available').length;
    
    // Borrowed excludes completed
    final borrowedCount = _userBookings!.where((b) => b.status == 'approved' || b.status == 'borrowed' || b.status == 'current' || b.status == 'confirmed').length;

    // Completed Exchanges
    final completedCount = _userBookings!.where((b) => b.status == 'completed').length +
        _ownerBookings!.where((b) => b.status == 'completed').length;

    final rating = _getAverageRating();

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        TappableCard(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MyEquipmentsPage(currentUser: user)),
            );
          },
          child: _buildStatCard(
            'Shared Items',
            sharedCount.toDouble(),
            Icons.inventory_2_outlined,
            AppColors.primary,
            prefix: '📦',
          ),
        ),
        TappableCard(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MyBookingsPage(currentUser: user)),
            );
          },
          child: _buildStatCard(
            'Items Borrowed',
            borrowedCount.toDouble(),
            Icons.shopping_bag_outlined,
            const Color(0xFF2196F3),
            prefix: '📥',
          ),
        ),
        TappableCard(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MyBookingsPage(currentUser: user)),
            );
          },
          child: _buildStatCard(
            'Completed Exchanges',
            completedCount.toDouble(),
            Icons.swap_horiz_outlined,
            const Color(0xFFE65100),
            prefix: '🤝',
          ),
        ),
        TappableCard(
          onTap: _showReviewsSheet,
          child: _buildStatCard(
            'Community Rating',
            rating,
            Icons.star_outline_rounded,
            const Color(0xFFF57F17),
            prefix: '⭐',
            isRating: true,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    double value,
    IconData icon,
    Color accentColor, {
    required String prefix,
    bool isRating = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEFF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(prefix, style: const TextStyle(fontSize: 18)),
              Icon(icon, color: accentColor, size: 20),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedCountText(
                value: value,
                isRating: isRating,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEFF0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 24, height: 24, decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle)),
              Container(width: 24, height: 24, decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 48, height: 22, color: Colors.grey[200]),
              const SizedBox(height: 6),
              Container(width: 80, height: 11, color: Colors.grey[200]),
            ],
          ),
        ],
      ),
    );
  }

  // --- LOCATION MANAGEMENT ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndFetchLocationSilently();
    }
  }

  Future<void> _checkAndFetchLocationSilently() async {
    final status = await LocationService.instance.checkPermissionStatus();
    if (status == LocationPermissionStatus.granted) {
      await _refreshGpsLocation(silent: true);
    }
  }

  Future<void> _refreshGpsLocation({bool silent = false}) async {
    if (_fetchingLocation) return;
    if (!silent) {
      setState(() {
        _fetchingLocation = true;
        _locationError = null;
      });
    }

    try {
      final status = await LocationService.instance.checkPermissionStatus();
      if (status != LocationPermissionStatus.granted) {
        if (!silent) {
          setState(() {
            _fetchingLocation = false;
            _locationError = 'Permission not granted.';
          });
        }
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!silent) {
          setState(() {
            _fetchingLocation = false;
            _locationError = 'GPS is disabled.';
          });
        }
        return;
      }

      Position? position;
      String? errorMsg;
      for (int i = 0; i < 3; i++) {
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 15),
          );
          if (position.accuracy <= 100) {
            break;
          } else {
            errorMsg = 'Accuracy is poor: ${position.accuracy} meters.';
          }
        } catch (e) {
          errorMsg = e.toString();
          if (i < 2) await Future.delayed(const Duration(seconds: 1));
        }
      }

      if (position == null) {
        throw Exception(errorMsg ?? 'Could not retrieve GPS coordinates.');
      }

      final location = await LocationService.instance.cachePosition(position);

      final uid = widget.currentUser.userId;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
        'accuracy': position.accuracy,
      });

      if (mounted) {
        final lp = context.read<LocationProvider>();
        await lp.recheckAndRefresh();
      }

      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPS Location updated successfully!'), backgroundColor: AppColors.primary),
        );
      }
    } catch (e) {
      debugPrint('[Profile Location] Error refreshing GPS: $e');
      if (!silent && mounted) {
        setState(() {
          _locationError = 'Unable to refresh GPS coordinates.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _fetchingLocation = false;
        });
      }
    }
  }

  Future<void> _handleLocationButtonClick() async {
    final status = await LocationService.instance.checkPermissionStatus();
    if (status == LocationPermissionStatus.serviceDisabled) {
      await LocationService.instance.openLocationSettings();
    } else if (status == LocationPermissionStatus.denied) {
      final newStatus = await LocationService.instance.requestPermission();
      if (newStatus == LocationPermissionStatus.granted) {
        await _refreshGpsLocation();
      }
    } else if (status == LocationPermissionStatus.permanentlyDenied) {
      await LocationService.instance.openAppPermissionSettings();
    } else {
      await _refreshGpsLocation();
    }
  }

  String _getLocationLastUpdatedString(DateTime? dt) {
    if (dt == null) return 'Never';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildLocationManagementSection(AppUserModel user) {
    final gpsEnabled = user.latitude != null && user.longitude != null;
    final accuracyStr = user.accuracy != null ? '${user.accuracy!.toStringAsFixed(1)}m' : 'Not Available';
    final lastUpdatedStr = user.locationUpdatedAt != null ? _getLocationLastUpdatedString(user.locationUpdatedAt) : 'Never';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEBEFF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Location',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
              ),
              const Spacer(),
              if (_fetchingLocation)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildLocationInfoRow('State', user.selectedState ?? 'Not Set'),
          const SizedBox(height: 10),
          
          _buildLocationInfoRow(
            'GPS Status', 
            gpsEnabled ? 'Enabled' : 'Location not enabled',
            valueColor: gpsEnabled ? Colors.green : Colors.redAccent,
          ),
          const SizedBox(height: 10),
          
          _buildLocationInfoRow('GPS Accuracy', accuracyStr),
          const SizedBox(height: 10),
          
          _buildLocationInfoRow('Last Sync', lastUpdatedStr),
          const SizedBox(height: 20),

          if (_locationError != null) ...[
            Text(
              _locationError!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
          ],

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => _showStatePicker(setState, user),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Change State', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _fetchingLocation ? null : _handleLocationButtonClick,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      gpsEnabled ? 'Refresh GPS' : 'Enable Location',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14, 
            color: valueColor ?? AppColors.textPrimary, 
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showStatePicker(StateSetter modalStateSetter, AppUserModel user) {
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
                            final isSelected = user.selectedState == stateName;
                            return ListTile(
                              title: Text(
                                stateName,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? AppColors.primary : Colors.black87,
                                ),
                              ),
                              trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                              onTap: () async {
                                Navigator.pop(context);
                                try {
                                  final uid = widget.currentUser.userId;
                                  await FirebaseFirestore.instance.collection('users').doc(uid).update({
                                    'selectedState': stateName,
                                  });
                                  
                                  if (mounted) {
                                    final lp = context.read<LocationProvider>();
                                    await lp.updateManualState(stateName);
                                  }

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('State updated to $stateName successfully!'), backgroundColor: AppColors.primary),
                                    );
                                  }
                                } catch (e) {
                                  debugPrint('[Profile Location] Error updating state: $e');
                                }
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
}

class TappableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const TappableCard({super.key, required this.child, required this.onTap});

  @override
  State<TappableCard> createState() => _TappableCardState();
}

class _TappableCardState extends State<TappableCard> with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = 0.95);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: Transform.scale(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

class AnimatedCountText extends StatefulWidget {
  final double value;
  final String suffix;
  final TextStyle style;
  final bool isRating;

  const AnimatedCountText({
    super.key,
    required this.value,
    this.suffix = '',
    required this.style,
    this.isRating = false,
  });

  @override
  State<AnimatedCountText> createState() => _AnimatedCountTextState();
}

class _AnimatedCountTextState extends State<AnimatedCountText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCountText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(begin: oldWidget.value, end: widget.value).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final val = _animation.value;
        String displayStr = val.toInt().toString();
        if (widget.isRating) {
          displayStr = widget.value == 0.0 ? 'New Member' : val.toStringAsFixed(1);
        }
        return Text(
          '$displayStr${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}
