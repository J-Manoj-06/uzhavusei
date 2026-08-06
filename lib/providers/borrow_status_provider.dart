import 'dart:async';
import 'package:flutter/material.dart';
import '../services/borrow_status_service.dart';

class BorrowStatusProvider with ChangeNotifier {
  BorrowStatusState _state = const BorrowStatusState();
  StreamSubscription<BorrowStatusState>? _subscription;
  bool _dismissedInCurrentSession = false;

  BorrowStatusState get state => _state;
  bool get shouldShowApprovalPopup =>
      _state.hasApprovedRequest && !_state.hasActiveTransaction && !_dismissedInCurrentSession;

  void init(String uid) {
    _subscription?.cancel();
    if (uid.isEmpty) return;

    _subscription = BorrowStatusService.instance.watchBorrowStatus(uid).listen((statusState) {
      _state = statusState;
      // If transaction is issued, reset dismissal state
      if (statusState.hasActiveTransaction) {
        _dismissedInCurrentSession = false;
      }
      notifyListeners();
    });
  }

  void dismissPopupForSession() {
    _dismissedInCurrentSession = true;
    notifyListeners();
  }

  void resetSessionDismissalOnResume() {
    _dismissedInCurrentSession = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
