import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/app_user_model.dart';
import '../../../services/auth_service.dart';
import '../../shell/marketplace_shell.dart';
import 'login_register_page.dart';
import 'role_selection_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.authService,
  });

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authService.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _CenteredLoader();
        }

        final user = authSnapshot.data;
        if (user == null) {
          return LoginRegisterPage(authService: authService);
        }

        return StreamBuilder<AppUserModel?>(
          stream: authService.watchCurrentUserProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _CenteredLoader();
            }

            final profile = profileSnapshot.data;
            if (profile == null || profile.role.trim().isEmpty) {
              return RoleSelectionPage(authService: authService);
            }

            return MarketplaceShell(
              authService: authService,
              currentUser: profile,
            );
          },
        );
      },
    );
  }
}

class _CenteredLoader extends StatelessWidget {
  const _CenteredLoader();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
