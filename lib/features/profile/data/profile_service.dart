import 'dart:async';
import '../../../models/app_user_model.dart';
import '../../../models/marketplace_equipment_model.dart';
import '../../../models/marketplace_booking_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/marketplace_service.dart';

class ProfileData {
  final AppUserModel user;
  final List<MarketplaceEquipmentModel> equipments;
  final List<MarketplaceBookingModel> userBookings;
  final List<MarketplaceBookingModel> ownerBookings;
  final List<MarketplaceEquipmentModel> savedEquipments;

  ProfileData({
    required this.user,
    required this.equipments,
    required this.userBookings,
    required this.ownerBookings,
    required this.savedEquipments,
  });
}

class ProfileService {
  ProfileService._privateConstructor();
  static final ProfileService instance = ProfileService._privateConstructor();

  final MarketplaceService _marketplace = MarketplaceService();
  final AuthService _auth = AuthService();

  Stream<ProfileData> watchProfileData(String userId) {
    late StreamController<ProfileData> controller;
    StreamSubscription? userSub;
    StreamSubscription? equipSub;
    StreamSubscription? userBookingsSub;
    StreamSubscription? ownerBookingsSub;
    StreamSubscription? savedSub;

    AppUserModel? lastUser;
    List<MarketplaceEquipmentModel>? lastEquipments;
    List<MarketplaceBookingModel>? lastUserBookings;
    List<MarketplaceBookingModel>? lastOwnerBookings;
    List<MarketplaceEquipmentModel>? lastSaved;

    void tryEmit() {
      if (lastUser != null &&
          lastEquipments != null &&
          lastUserBookings != null &&
          lastOwnerBookings != null &&
          lastSaved != null) {
        if (!controller.isClosed) {
          controller.add(ProfileData(
            user: lastUser!,
            equipments: lastEquipments!,
            userBookings: lastUserBookings!,
            ownerBookings: lastOwnerBookings!,
            savedEquipments: lastSaved!,
          ));
        }
      }
    }

    controller = StreamController<ProfileData>(
      onListen: () {
        userSub = _auth.watchCurrentUserProfile().listen((u) {
          if (u != null) {
            lastUser = u;
            tryEmit();
          }
        }, onError: (e) {
          if (!controller.isClosed) controller.addError(e);
        });

        equipSub = _marketplace.watchEquipmentsByOwner(userId).listen((e) {
          lastEquipments = e;
          tryEmit();
        }, onError: (e) {
          if (!controller.isClosed) controller.addError(e);
        });

        userBookingsSub = _marketplace.watchUserBookings(userId).listen((ub) {
          lastUserBookings = ub;
          tryEmit();
        }, onError: (e) {
          if (!controller.isClosed) controller.addError(e);
        });

        ownerBookingsSub = _marketplace.watchOwnerBookings(userId).listen((ob) {
          lastOwnerBookings = ob;
          tryEmit();
        }, onError: (e) {
          if (!controller.isClosed) controller.addError(e);
        });

        savedSub = _marketplace.watchSavedEquipments(userId).listen((s) {
          lastSaved = s;
          tryEmit();
        }, onError: (e) {
          if (!controller.isClosed) controller.addError(e);
        });
      },
      onCancel: () {
        userSub?.cancel();
        equipSub?.cancel();
        userBookingsSub?.cancel();
        ownerBookingsSub?.cancel();
        savedSub?.cancel();
      },
    );

    return controller.stream;
  }
}
