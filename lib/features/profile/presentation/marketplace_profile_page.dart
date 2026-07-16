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

class _MarketplaceProfilePageState extends State<MarketplaceProfilePage> {
  final MarketplaceService _service = MarketplaceService();

  StreamSubscription? _equipmentSub;
  StreamSubscription? _userBookingsSub;
  StreamSubscription? _ownerBookingsSub;

  List<MarketplaceEquipmentModel>? _equipments;
  List<MarketplaceBookingModel>? _userBookings;
  List<MarketplaceBookingModel>? _ownerBookings;

  bool _loadingStats = true;
  bool _errorStats = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _cancelSubscriptions() {
    _equipmentSub?.cancel();
    _userBookingsSub?.cancel();
    _ownerBookingsSub?.cancel();
  }

  void _loadStats() {
    setState(() {
      _loadingStats = true;
      _errorStats = false;
    });

    _cancelSubscriptions();

    try {
      final user = widget.currentUser;

      _equipmentSub = _service.watchEquipmentsByOwner(user.userId).listen(
        (equipments) {
          if (!mounted) return;
          setState(() {
            _equipments = equipments;
            _checkLoaded();
          });
        },
        onError: (err) {
          LoggerService.error('Error loading equipments', err);
          setState(() => _errorStats = true);
        },
      );

      _userBookingsSub = _service.watchUserBookings(user.userId).listen(
        (bookings) {
          if (!mounted) return;
          setState(() {
            _userBookings = bookings;
            _checkLoaded();
          });
        },
        onError: (err) {
          LoggerService.error('Error loading user bookings', err);
          setState(() => _errorStats = true);
        },
      );

      _ownerBookingsSub = _service.watchOwnerBookings(user.userId).listen(
        (bookings) {
          if (!mounted) return;
          setState(() {
            _ownerBookings = bookings;
            _checkLoaded();
          });
        },
        onError: (err) {
          LoggerService.error('Error loading owner bookings', err);
          setState(() => _errorStats = true);
        },
      );
    } catch (e) {
      LoggerService.error('Error setting up streams', e);
      setState(() => _errorStats = true);
    }
  }

  void _checkLoaded() {
    if (_equipments != null && _userBookings != null && _ownerBookings != null) {
      setState(() {
        _loadingStats = false;
      });
    }
  }

  @override
  void dispose() {
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
              const Text('Ratings & Reviews', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A1A1A))),
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
                leading: CircleAvatar(backgroundColor: Colors.green[50], child: const Text('A')),
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
  Widget build(BuildContext context) {
    return StreamBuilder<AppUserModel?>(
      stream: widget.authService.watchCurrentUserProfile(),
      builder: (context, snapshot) {
        final user = snapshot.data ?? widget.currentUser;

        // Formatted location
        final locationParts = [user.village, user.district, user.state]
            .where((e) => e != null && e.trim().isNotEmpty)
            .toList();
        final displayLoc = locationParts.isNotEmpty ? '📍 ${locationParts.first}' : '📍 Location not set';

        // Username
        final displayUsername = user.username != null && user.username!.trim().isNotEmpty
            ? '@${user.username!.trim().replaceAll('@', '')}'
            : 'Add username';

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAF8),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            title: const Text(
              'Profile',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              _loadStats();
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: const Color(0xFF2E7D32),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    
                    // Large Profile Photo
                    Center(
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: const Color(0xFFE8F5E9),
                        child: user.profileImage.trim().isNotEmpty
                            ? ClipOval(
                                child: buildSmartImage(
                                  user.profileImage,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.person, size: 60, color: Color(0xFF2E7D32)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Full Name
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          user.name.isEmpty || user.name == 'User' ? 'Complete your profile' : user.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: Colors.blue, size: 20),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Username
                    GestureDetector(
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
                          fontSize: 14,
                          color: user.username != null && user.username!.isNotEmpty
                              ? Colors.grey.shade600
                              : const Color(0xFF2E7D32),
                          fontWeight: user.username != null && user.username!.isNotEmpty
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Approximate Location
                    Text(
                      displayLoc,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Member Since
                    Text(
                      'Member since ${user.createdAt.year}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Optional Short Bio
                    if (user.bio != null && user.bio!.trim().isNotEmpty) ...[
                      Container(
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
                            fontSize: 14,
                            color: Colors.grey.shade800,
                            height: 1.4,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Edit Profile Button
                    SizedBox(
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
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Statistics Grid Section
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Activity Statistics',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildStatsDashboard(user),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
        childAspectRatio: 1.25,
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
      childAspectRatio: 1.25,
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
            const Color(0xFF2E7D32),
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
      padding: const EdgeInsets.all(16),
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
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
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
