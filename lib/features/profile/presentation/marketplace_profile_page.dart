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

class MarketplaceProfilePage extends StatelessWidget {
  const MarketplaceProfilePage({
    super.key,
    required this.currentUser,
    required this.authService,
  });

  final AppUserModel currentUser;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUserModel?>(
      stream: authService.watchCurrentUserProfile(),
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context);
        final user = snapshot.data ?? currentUser;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.tr('profile')),
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _profileHeader(context, user, l10n),
              const SizedBox(height: 14),
              _quickActions(context, user, l10n),
            ],
          ),
        );
      },
    );
  }

  Widget _profileHeader(
    BuildContext context,
    AppUserModel user,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFFE8F5E9),
            child: user.profileImage.trim().isNotEmpty
                ? ClipOval(
                    child: buildSmartImage(
                      user.profileImage,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.person, size: 40, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 12),
          Text(
            user.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(user.email),
          const SizedBox(height: 2),
          Text('${l10n.tr('role')}: ${user.role.isEmpty ? '-' : user.role}'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfilePage(
                    initialUser: user,
                    authService: authService,
                  ),
                ),
              ),
              icon: const Icon(Icons.edit),
              label: Text(l10n.tr('edit_profile')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActions(
    BuildContext context,
    AppUserModel user,
    AppLocalizations l10n,
  ) {
    final actions = <_ActionItem>[
      if (user.isOwner)
        _ActionItem(
          icon: Icons.agriculture,
          title: l10n.tr('my_equipments'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => MyEquipmentsPage(currentUser: user)),
          ),
        ),
      _ActionItem(
        icon: Icons.receipt_long,
        title: l10n.tr('my_bookings_orders'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MyBookingsPage(currentUser: user)),
        ),
      ),
      _ActionItem(
        icon: Icons.language,
        title: l10n.tr('language_settings'),
        onTap: () => _showLanguageSheet(context, user.language),
      ),
      _ActionItem(
        icon: Icons.support_agent,
        title: l10n.tr('help_support'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MaintenancePage()),
        ),
      ),
      _ActionItem(
        icon: Icons.logout,
        title: l10n.tr('logout'),
        onTap: authService.signOut,
        danger: true,
      ),
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            ListTile(
              leading: Icon(
                actions[i].icon,
                color: actions[i].danger ? Colors.red : const Color(0xFF2E7D32),
              ),
              title: Text(actions[i].title),
              trailing: const Icon(Icons.chevron_right),
              onTap: actions[i].onTap,
            ),
            if (i < actions.length - 1) const Divider(height: 1, thickness: 1),
          ],
        ],
      ),
    );
  }

  Future<void> _showLanguageSheet(BuildContext context, String selected) async {
    final l10n = AppLocalizations.of(context);
    final localeProvider = context.read<LocaleProvider>();

    final selectedCode = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.tr('select_language')),
              ),
              _languageTile(
                context: context,
                title: l10n.tr('english'),
                code: 'en',
                selected: selected,
              ),
              _languageTile(
                context: context,
                title: l10n.tr('tamil'),
                code: 'ta',
                selected: selected,
              ),
              _languageTile(
                context: context,
                title: l10n.tr('hindi'),
                code: 'hi',
                selected: selected,
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );

    if (selectedCode == null || selectedCode == selected) return;

    localeProvider.setLanguageCode(selectedCode);
    try {
      await authService.updateLanguage(selectedCode);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tr('error_occurred'))),
      );
    }
  }

  Widget _languageTile({
    required BuildContext context,
    required String title,
    required String code,
    required String selected,
  }) {
    return ListTile(
      leading: Icon(
        selected == code
            ? Icons.radio_button_checked
            : Icons.radio_button_unchecked,
        color: const Color(0xFF4CAF50),
      ),
      title: Text(title),
      onTap: () => Navigator.pop(context, code),
    );
  }
}

class _ActionItem {
  const _ActionItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;
}
