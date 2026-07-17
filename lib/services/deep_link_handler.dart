import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/equipment/presentation/equipment_details_page.dart';
import '../models/app_user_model.dart';
import 'marketplace_service.dart';
import 'package:UzhavuSei/theme/app_theme.dart';

class DeepLinkHandler {
  DeepLinkHandler._privateConstructor();
  static final DeepLinkHandler instance = DeepLinkHandler._privateConstructor();

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  bool _isInitialized = false;

  void init(BuildContext context, AppUserModel currentUser) {
    if (_isInitialized) return;
    _isInitialized = true;
    _appLinks = AppLinks();

    // Handle links that were used to open the app (cold start)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleDeepLink(context, uri, currentUser);
      }
    });

    // Handle links while the app is already running (warm start)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(context, uri, currentUser);
    }, onError: (err) {
      debugPrint('Deep Link Error: $err');
    });
  }

  void dispose() {
    _linkSubscription?.cancel();
    _isInitialized = false;
  }

  Future<void> _handleDeepLink(BuildContext context, Uri uri, AppUserModel currentUser) async {
    // Example: https://uzhavusei-a8be3.web.app/equipment/abc123
    final pathSegments = uri.pathSegments;
    if (pathSegments.isEmpty) return;

    final type = pathSegments[0]; // 'equipment' or 'surplus'
    final listingId = pathSegments.length > 1 ? pathSegments[1] : null;

    if (listingId == null || listingId.isEmpty) return;

    final marketplaceService = MarketplaceService();

    if (type == 'equipment') {
      _showLoading(context);
      final item = await marketplaceService.getEquipmentById(listingId);
      _hideLoading(context);

      if (item != null) {
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EquipmentDetailsPage(
                equipment: item,
                userId: currentUser.userId,
                userName: currentUser.name,
                userEmail: currentUser.email,
                userPhone: currentUser.phoneNumber,
              ),
            ),
          );
        }
      } else {
        _showError(context, 'This equipment listing is no longer available.');
      }
    } else if (type == 'surplus') {
      _showLoading(context);
      final item = await marketplaceService.getSurplusById(listingId);
      _hideLoading(context);

      // Assuming there's a SurplusDetailsPage in the app
      /*
      if (item != null) {
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SurplusDetailsPage(
                item: item,
                userId: currentUserId,
              ),
            ),
          );
        }
      } else {
        _showError(context, 'This surplus listing is no longer available.');
      }
      */
    }
  }

  void _showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  void _hideLoading(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Logs a share event to Firebase Analytics / Firestore
  static Future<void> logShareEvent(String listingId, String sharedByUserId) async {
    try {
      await FirebaseFirestore.instance.collection('shared_links_analytics').add({
        'listingId': listingId,
        'sharedBy': sharedByUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'app', // or dynamic based on Platform.isIOS
      });
    } catch (e) {
      debugPrint('Failed to log share event: $e');
    }
  }
}
