import 'dart:async';
import 'package:flutter/material.dart';
import '../services/borrow_lifecycle_service.dart';

class BorrowEligibilityProvider with ChangeNotifier {
  BorrowLifecycleState _state = BorrowLifecycleState.eligible();
  StreamSubscription<BorrowLifecycleState>? _subscription;
  String? _lastNotifiedReturnTxId;

  BorrowLifecycleState get state => _state;
  bool get isEligible => _state.isEligible;
  String? get newlyReturnedTxId => _lastNotifiedReturnTxId;

  void init(String uid) {
    _subscription?.cancel();
    if (uid.isEmpty) return;

    _subscription = BorrowLifecycleService.instance.watchStudentLifecycle(uid).listen((lifecycleState) {
      final prevWasIneligible = !_state.isEligible;
      _state = lifecycleState;

      // Detect book return completion event
      final lastReturnedId = lifecycleState.lastReturnedTransaction?['id'];
      if (prevWasIneligible && lifecycleState.isEligible && lastReturnedId != null && lastReturnedId != _lastNotifiedReturnTxId) {
        _lastNotifiedReturnTxId = lastReturnedId;
      }
      notifyListeners();
    });
  }

  void clearReturnNotification() {
    _lastNotifiedReturnTxId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
