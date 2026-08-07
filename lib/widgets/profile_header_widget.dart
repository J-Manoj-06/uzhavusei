import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user_model.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import 'image_loader.dart';
import 'profile_menu_sheet.dart';

class ProfileHeaderWidget extends StatelessWidget {
  const ProfileHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      return GestureDetector(
        onTap: () => ProfileMenuSheet.show(context),
        child: const CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primaryContainer,
          child: Icon(Icons.person_outline_rounded, size: 20, color: AppColors.primary),
        ),
      );
    }

    return StreamBuilder<AppUserModel?>(
      stream: ProfileService.instance.watchUserProfile(uid),
      builder: (context, profileSnapshot) {
        final profile = profileSnapshot.data;
        final photoUrl = profile?.profileImage ?? '';

        return StreamBuilder<int>(
          stream: ProfileService.instance.watchUnreadNotificationCount(uid),
          builder: (context, notifSnapshot) {
            final unreadCount = notifSnapshot.data ?? 0;

            return GestureDetector(
              onTap: () => ProfileMenuSheet.show(context),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryContainer, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primaryContainer,
                      child: photoUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: SizedBox(
                                width: 36,
                                height: 36,
                                child: buildSmartImage(photoUrl, fit: BoxFit.cover, isBook: false),
                              ),
                            )
                          : const Icon(Icons.person_outline_rounded, size: 20, color: AppColors.primary),
                    ),
                  ),

                  // Unread Notification Dot Badge
                  if (unreadCount > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
