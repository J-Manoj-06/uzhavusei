import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/app_user_model.dart';
import '../../../services/auth_service.dart';
import '../../shell/marketplace_shell.dart';
import 'login_register_page.dart';
import 'role_selection_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.authService,
  });

  final AuthService authService;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  User? _lastAuthedUser;
  AppUserModel? _lastProfile;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: widget.authService.authStateChanges(),
      initialData: widget.authService.currentUser,
      builder: (context, authSnapshot) {
        final user = authSnapshot.data ?? _lastAuthedUser;
        if (authSnapshot.connectionState == ConnectionState.waiting &&
            user == null) {
          return const _CenteredLoader();
        }

        if (user == null) {
          _lastAuthedUser = null;
          _lastProfile = null;
          return LoginRegisterPage(authService: widget.authService);
        }
        _lastAuthedUser = user;

        return StreamBuilder<AppUserModel?>(
          stream: widget.authService.watchCurrentUserProfile(),
          initialData: _lastProfile,
          builder: (context, profileSnapshot) {
            final profile = profileSnapshot.data ?? _lastProfile;

            if (profileSnapshot.connectionState == ConnectionState.waiting &&
                profile == null) {
              return const _CenteredLoader();
            }

            if (profile == null || profile.role.trim().isEmpty) {
              return RoleSelectionPage(authService: widget.authService);
            }

            _lastProfile = profile;

            return MarketplaceShell(
              authService: widget.authService,
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
