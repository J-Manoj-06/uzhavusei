import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Maintenance.dart';
import '../../../localization/app_localizations.dart';
import '../../../models/app_user_model.dart';
import '../../../providers/locale_provider.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/image_loader.dart';
import 'edit_profile_page.dart';
import 'my_bookings_page.dart';
import 'my_equipments_page.dart';
import '../../../TransactionsPage.dart';

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
  // Expansion states
  bool _activityExpanded = false;
  bool _equipmentExpanded = false;
  bool _marketplaceExpanded = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUserModel?>(
      stream: widget.authService.watchCurrentUserProfile(),
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context);
        final user = snapshot.data ?? widget.currentUser;

        return Scaffold(
          backgroundColor: const Color(0xFFF9F9F8),
          appBar: _buildAppBar(),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeroProfileSection(user),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildProfileCompletion(),
                      const SizedBox(height: 16),
                      _buildQuickStats(),
                      const SizedBox(height: 24),
                      _buildAgriculturalFeatures(),
                      const SizedBox(height: 16),
                      _buildActivityGroup(user, l10n),
                      const SizedBox(height: 16),
                      _buildEquipmentManagement(user, l10n),
                      const SizedBox(height: 16),
                      _buildMarketplaceGroup(),
                      const SizedBox(height: 16),
                      _buildSettingsGroup(l10n),
                      const SizedBox(height: 24),
                      _buildLogoutButton(l10n),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AppBar(
            backgroundColor: Colors.white.withValues(alpha: 0.7),
            elevation: 0,
            title: Row(
              children: [
                const Icon(Icons.agriculture, color: Color(0xFF4CAF50)),
                const SizedBox(width: 8),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF006E1C), Color(0xFF77A67A)],
                  ).createShader(bounds),
                  child: const Text(
                    'UzhavuSei',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Color(0xFF3F4A3C)),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(
                color: const Color(0xFFBECAB9).withValues(alpha: 0.2),
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroProfileSection(AppUserModel user) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Background Gradient
        Container(
          height: 160,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF006E1C), Color(0xFF4CAF50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 16,
                left: 16,
                child: Icon(Icons.agriculture, size: 60, color: Colors.white.withValues(alpha: 0.1)),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Transform.rotate(
                  angle: 0.2,
                  child: Icon(Icons.grass, size: 80, color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
            ],
          ),
        ),
        // Glassmorphism Card
        Container(
          margin: const EdgeInsets.only(top: 100, left: 16, right: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0E0E0).withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Profile Image
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFFE8F5E9),
                      child: user.profileImage.trim().isNotEmpty
                          ? ClipOval(
                              child: buildSmartImage(
                                user.profileImage,
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.person, size: 50, color: Color(0xFF2E7D32)),
                    ),
                  ),
                  InkWell(
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
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFF006E1C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, size: 16, color: Colors.white),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user.name.isEmpty ? 'User' : user.name,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF191C1C)),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.verified, color: Color(0xFF006E1C), size: 24),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFED7CA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      user.role.isEmpty ? 'User' : user.role,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF795C51),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.location_on, size: 16, color: Color(0xFF3F4A3C)),
                  const SizedBox(width: 4),
                  const Text(
                    'Coimbatore, TN', // Placeholder
                    style: TextStyle(fontSize: 14, color: Color(0xFF3F4A3C)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Member since ${user.createdAt.year}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6F7A6B)),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCompletion() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEEED),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile Completion',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF3F4A3C)),
              ),
              Text(
                '85%',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF006E1C)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.85,
              backgroundColor: Color(0x4DBECAB9),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006E1C)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete your bank details to start earning from rentals.',
            style: TextStyle(fontSize: 12, color: Color(0xFF6F7A6B)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _buildStatBox('12', 'Equipment'),
        const SizedBox(width: 12),
        _buildStatBox('45', 'Rentals'),
        const SizedBox(width: 12),
        _buildStatBox('08', 'Orders'),
        const SizedBox(width: 12),
        _buildStatBox('15', 'Wishlist'),
      ],
    );
  }

  Widget _buildStatBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBECAB9).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF006E1C)),
            ),
            Text(
              label.toUpperCase(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF3F4A3C)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgriculturalFeatures() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBECAB9).withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Icon(Icons.eco, color: Color(0xFF006E1C)),
                SizedBox(width: 12),
                Text(
                  'Agricultural Profile',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildAgriFeatureRow(Icons.landscape, 'Land Area', '5 Acres'),
                    ),
                    Expanded(
                      child: _buildAgriFeatureRow(Icons.eco, 'Primary Crops', 'Paddy, Sugarcane'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildAgriFeatureRow(Icons.radar, 'Service Radius', '20km Range'),
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgriFeatureRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF006E1C)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title, 
                style: const TextStyle(fontSize: 12, color: Color(0xFF6F7A6B)),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value, 
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildActivityGroup(AppUserModel user, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildListTile('My Transactions', icon: Icons.receipt_long, onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TransactionsPage()),
        );
      }),
    );
  }

  Widget _buildEquipmentManagement(AppUserModel user, AppLocalizations l10n) {
    return _buildCollapsibleSection(
      icon: Icons.precision_manufacturing,
      title: 'Equipment Management',
      isExpanded: _equipmentExpanded,
      onToggle: () => setState(() => _equipmentExpanded = !_equipmentExpanded),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.payments, color: Color(0xFF006E1C)),
                          SizedBox(height: 8),
                          Text('Total Earnings', style: TextStyle(fontSize: 12, color: Color(0xFF6F7A6B))),
                          Text('₹42,500', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFED7CA).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.list_alt, color: Color(0xFF75584D)),
                          SizedBox(height: 8),
                          Text('Active Listings', style: TextStyle(fontSize: 12, color: Color(0xFF6F7A6B))),
                          Text('04 Units', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (user.isOwner) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MyEquipmentsPage(currentUser: user)),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('You need to be an owner to add equipment')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006E1C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Equipment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMarketplaceGroup() {
    return _buildCollapsibleSection(
      icon: Icons.storefront,
      title: 'Marketplace',
      isExpanded: _marketplaceExpanded,
      onToggle: () => setState(() => _marketplaceExpanded = !_marketplaceExpanded),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFBECAB9)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Text('0', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text('My Products', style: TextStyle(fontSize: 12, color: Color(0xFF6F7A6B))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFBECAB9)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Text('12', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text('Saved Items', style: TextStyle(fontSize: 12, color: Color(0xFF6F7A6B))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsGroup(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildListTile('Language Settings', icon: Icons.language, onTap: () {
            _showLanguageSheet(context);
          }),
          const Divider(height: 1, color: Color(0x1ABECAB9)),
          _buildListTile('Help & Support', icon: Icons.help_outline, onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MaintenancePage()),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required IconData icon,
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: isExpanded 
                ? const BorderRadius.vertical(top: Radius.circular(16))
                : BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icon, color: const Color(0xFF3F4A3C)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: const Color(0xFF6F7A6B)),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0x1ABECAB9))),
              ),
              child: Column(children: children),
            ),
        ],
      ),
    );
  }

  Widget _buildListTile(String title, {IconData? icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: const Color(0xFF3F4A3C)),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF6F7A6B)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutDialog(context, l10n),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Color(0xFF006E1C)),
          foregroundColor: const Color(0xFF006E1C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.logout),
        label: const Text('Logout', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Select Language',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('English'),
                onTap: () {
                  localeProvider.setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('தமிழ் (Tamil)'),
                onTap: () {
                  localeProvider.setLocale(const Locale('ta'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('हिंदी (Hindi)'),
                onTap: () {
                  localeProvider.setLocale(const Locale('hi'));
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.tr('logout')),
        content: Text(l10n.tr('logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.tr('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.authService.signOut();
            },
            child: Text(
              l10n.tr('logout'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
