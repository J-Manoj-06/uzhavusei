import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user_model.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import 'image_loader.dart';
import '../pages/my_library/my_library_page.dart';
import '../features/profile/presentation/marketplace_profile_page.dart';
import '../features/profile/presentation/my_listings_page.dart';
import '../features/profile/presentation/settings_page.dart';
import '../features/profile/presentation/complete_profile_page.dart';

class ProfileMenuSheet extends StatelessWidget {
  final String uid;

  const ProfileMenuSheet({super.key, required this.uid});

  static Future<void> show(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return Future.value();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProfileMenuSheet(uid: uid),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUserModel?>(
      stream: ProfileService.instance.watchUserProfile(uid),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final user = FirebaseAuth.instance.currentUser;
        final fallbackUser = profile ?? AppUserModel.empty(uid, user?.email ?? '');

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // User Header Info Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      // Profile Avatar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(36),
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: buildSmartImage(
                            fallbackUser.profileImage,
                            fit: BoxFit.cover,
                            isBook: false,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fallbackUser.fullName.isNotEmpty ? fallbackUser.fullName : 'Student User',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              fallbackUser.collegeEmail,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            // Academic Tags (Dept, Year, Reg No)
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (fallbackUser.department.isNotEmpty)
                                  _buildSmallTag(fallbackUser.department, AppColors.primaryContainer, AppColors.primary),
                                if (fallbackUser.year.isNotEmpty)
                                  _buildSmallTag('${fallbackUser.year} Year', Colors.blue.shade50, Colors.blue.shade700),
                                if (fallbackUser.registerNumber.isNotEmpty)
                                  _buildSmallTag('Reg: ${fallbackUser.registerNumber}', Colors.grey.shade100, Colors.grey.shade700),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Complete Profile Warning Banner (if incomplete)
                if (!fallbackUser.isProfileComplete) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CompleteProfilePage(
                              authService: AuthService(),
                              initialUser: fallbackUser,
                              isMandatory: false,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFEDD5)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.warning_amber_rounded, color: Color(0xFFC2410C), size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Profile Incomplete — Tap to complete details',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFC2410C)),
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: Color(0xFFC2410C), size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                const Divider(height: 16),

                // Menu Items
                _buildMenuItem(
                  context,
                  icon: Icons.person_outline_rounded,
                  title: 'View Profile',
                  subtitle: 'Edit personal information and academic profile',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MarketplaceProfilePage(
                          currentUser: fallbackUser,
                          authService: AuthService(),
                        ),
                      ),
                    );
                  },
                ),

                _buildMenuItem(
                  context,
                  icon: Icons.collections_bookmark_outlined,
                  title: 'My Library',
                  subtitle: 'Manage borrow requests, collection & history',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MyLibraryPage(currentUser: fallbackUser),
                      ),
                    );
                  },
                ),

                _buildMenuItem(
                  context,
                  icon: Icons.grid_view_rounded,
                  title: 'My Listings',
                  subtitle: 'View listed equipment and surplus items',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MyListingsPage(
                          currentUser: fallbackUser,
                        ),
                      ),
                    );
                  },
                ),

                // Notifications Item with Unread Count Badge
                StreamBuilder<int>(
                  stream: ProfileService.instance.watchUnreadNotificationCount(uid),
                  builder: (context, notifSnapshot) {
                    final unreadCount = notifSnapshot.data ?? 0;

                    return _buildMenuItem(
                      context,
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      subtitle: unreadCount > 0 ? '$unreadCount unread updates' : 'No unread notifications',
                      trailing: unreadCount > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notifications are up to date!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  },
                ),

                _buildMenuItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: 'Theme, language, app preferences',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsPage(
                          currentUser: fallbackUser,
                          authService: AuthService(),
                        ),
                      ),
                    );
                  },
                ),

                _buildMenuItem(
                  context,
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  subtitle: 'FAQ, contact support, about Borrow',
                  onTap: () {
                    Navigator.pop(context);
                    _showHelpSupportDialog(context);
                  },
                ),

                const Divider(height: 16),

                // Logout Button
                _buildMenuItem(
                  context,
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  subtitle: 'Sign out of your Borrow account',
                  textColor: Colors.red,
                  iconColor: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _confirmLogout(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSmallTag(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    Color textColor = AppColors.textPrimary,
    Color iconColor = AppColors.primary,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }

  void _showHelpSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.help_outline_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Help & Support', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Borrow App — College Library & Marketplace', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• For book borrowing queries, contact your college librarian.'),
            SizedBox(height: 4),
            Text('• For equipment or surplus issues, reach out to support@borrow.app.'),
            SizedBox(height: 12),
            Text('App Version: 1.0.4', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService().signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
