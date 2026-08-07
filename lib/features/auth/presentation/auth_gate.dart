import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/app_user_model.dart';
import '../../../services/auth_service.dart';
import '../../shell/marketplace_shell.dart';
import 'login_register_page.dart';
import 'verify_email_page.dart';
import '../../profile/presentation/complete_profile_page.dart';

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
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: widget.authService.authStateChanges(),
      initialData: widget.authService.currentUser,
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;

        if (authSnapshot.connectionState == ConnectionState.waiting &&
            user == null &&
            widget.authService.currentUser == null) {
          return const _CenteredLoader();
        }

        final activeUser = user ?? widget.authService.currentUser;

        if (activeUser == null) {
          return LoginRegisterPage(authService: widget.authService);
        }

        if (!activeUser.emailVerified) {
          return VerifyEmailPage(authService: widget.authService);
        }

        return StreamBuilder<AppUserModel?>(
          key: ValueKey(activeUser.uid),
          stream: widget.authService.watchCurrentUserProfile(activeUser.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting &&
                !profileSnapshot.hasData) {
              return const _CenteredLoader();
            }

            final profile = profileSnapshot.data;

            if (profile == null || !profile.isProfileComplete) {
              return CompleteProfilePage(
                authService: widget.authService,
                initialUser: profile ?? AppUserModel.empty(activeUser.uid, activeUser.email),
                isMandatory: true,
              );
            }

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
