import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

enum PaymentStatus { success, failed, cancelled }

class PaymentResult {
  const PaymentResult({
    required this.status,
    this.paymentId,
    this.errorMessage,
  });

  final PaymentStatus status;
  final String? paymentId;
  final String? errorMessage;
}

class PaymentRequest {
  const PaymentRequest({
    required this.key,
    required this.amountInPaise,
    required this.machineName,
    required this.bookingDate,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
  });

  final String key;
  final int amountInPaise;
  final String machineName;
  final String bookingDate;
  final String userName;
  final String userEmail;
  final String userPhone;
}

class RazorpayCheckoutService {
  RazorpayCheckoutService();

  Razorpay? _razorpay;
  Completer<PaymentResult>? _completer;

  bool _ensureInitialized() {
    if (_razorpay != null) return true;
    try {
      final razorpay = Razorpay();
      razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
      razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
      razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
      _razorpay = razorpay;
      return true;
    } on MissingPluginException catch (error, stackTrace) {
      debugPrint('Razorpay plugin unavailable: $error\n$stackTrace');
      return false;
    } catch (error, stackTrace) {
      debugPrint('Razorpay init failed: $error\n$stackTrace');
      return false;
    }
  }

  Future<PaymentResult> startPayment(PaymentRequest request) async {
    if (kIsWeb) {
      return const PaymentResult(
        status: PaymentStatus.failed,
        errorMessage: 'Razorpay mobile SDK is unavailable on web.',
      );
    }

    if (request.key.trim().isEmpty) {
      return const PaymentResult(
        status: PaymentStatus.failed,
        errorMessage: 'Missing Razorpay key. Add RAZORPAY_KEY_ID to .env',
      );
    }

    if (!_ensureInitialized()) {
      return const PaymentResult(
        status: PaymentStatus.failed,
        errorMessage:
            'Payment plugin not ready. Do a full app restart after pub get.',
      );
    }

    if (_completer != null && !_completer!.isCompleted) {
      return const PaymentResult(
        status: PaymentStatus.failed,
        errorMessage: 'Payment already in progress. Please wait.',
      );
    }

    final completer = Completer<PaymentResult>();
    _completer = completer;

    try {
      final options = {
        'key': request.key,
        'amount': request.amountInPaise,
        'name': 'UzhavuSei',
        'description': '${request.machineName} on ${request.bookingDate}',
        'prefill': {
          'contact': request.userPhone,
          'email': request.userEmail,
          'name': request.userName,
        },
        'theme': {'color': '#4CAF50'},
      };

      _razorpay!.open(options);
    } catch (error, stackTrace) {
      debugPrint('Razorpay open failed: $error\n$stackTrace');
      if (!completer.isCompleted) {
        completer.complete(
          const PaymentResult(
            status: PaymentStatus.failed,
            errorMessage: 'Unable to open payment gateway. Try again.',
          ),
        );
      }
    }

    return completer.future;
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) {
    if (_completer == null || _completer!.isCompleted) return;
    _completer!.complete(
      PaymentResult(
        status: PaymentStatus.success,
        paymentId: response.paymentId,
      ),
    );
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (_completer == null || _completer!.isCompleted) return;
    final message = response.message?.trim().isNotEmpty == true
        ? response.message!
        : 'Payment failed. Please try again.';

    final cancelled = (response.code == Razorpay.PAYMENT_CANCELLED) ||
        message.toLowerCase().contains('cancel');

    _completer!.complete(
      PaymentResult(
        status: cancelled ? PaymentStatus.cancelled : PaymentStatus.failed,
        errorMessage: message,
      ),
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    if (_completer == null || _completer!.isCompleted) return;
    _completer!.complete(
      PaymentResult(
        status: PaymentStatus.failed,
        errorMessage:
            'External wallet selected: ${response.walletName ?? 'unknown'}',
      ),
    );
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }
}
