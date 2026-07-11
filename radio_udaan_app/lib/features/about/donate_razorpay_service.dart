import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_error.dart';
import '../../core/api/radioudaan_api.dart';
import '../../core/config/app_branding.dart';
import '../../core/config/app_copy_accessors.dart';
import '../../core/models/donation_order.dart';

typedef DonationPaymentSuccess = void Function(DonationVerifyResult result);
typedef DonationPaymentFailure = void Function(String message);

/// Platform checkout: native Razorpay on Android, Payment Link (Safari) on iOS.
class DonateRazorpayService {
  DonateRazorpayService({
    required RadioUdaanApi api,
    required AppCopy copy,
  })  : _api = api,
        _copy = copy {
    _ensureAndroidSdk();
  }

  final RadioUdaanApi _api;
  final AppCopy _copy;
  Razorpay? _razorpay;

  DonationPaymentSuccess? onSuccess;
  DonationPaymentFailure? onFailure;

  String? _pendingOrderId;

  /// iOS / web use hosted Payment Link. Android uses native Checkout SDK.
  bool get usesPaymentLink {
    if (kIsWeb) return true;
    try {
      return Platform.isIOS;
    } catch (_) {
      return defaultTargetPlatform == TargetPlatform.iOS;
    }
  }

  String get checkoutPlatform {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isIOS) return 'ios';
      if (Platform.isAndroid) return 'android';
    } catch (_) {}
    return defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  }

  String? get pendingOrderId => _pendingOrderId;

  void _ensureAndroidSdk() {
    if (kIsWeb) return;
    try {
      if (!Platform.isAndroid) return;
    } catch (_) {
      if (defaultTargetPlatform != TargetPlatform.android) return;
    }
    if (_razorpay != null) return;
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onAndroidSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onAndroidError);
  }

  Future<DonationOrderResult> createOrder({
    required int amountPaise,
    bool want80g = false,
    String pan = '',
    String name = '',
    String email = '',
    String phone = '',
  }) {
    return _api.createDonationOrder(
      amountPaise: amountPaise,
      want80g: want80g,
      pan: pan,
      name: name,
      email: email,
      phone: phone,
      platform: checkoutPlatform,
    );
  }

  Future<void> startCheckout(DonationOrderResult order) async {
    _pendingOrderId = order.orderId;
    if (usesPaymentLink) {
      final link = order.paymentLink.trim();
      if (link.isEmpty) {
        onFailure?.call(_copy.donateFailedMessage);
        return;
      }
      final uri = Uri.tryParse(link);
      if (uri == null) {
        onFailure?.call(_copy.donateFailedMessage);
        return;
      }
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        onFailure?.call(_copy.donateFailedMessage);
      }
      return;
    }

    // Android: native Razorpay Checkout (may show Custom Tab UI — that is the SDK).
    _ensureAndroidSdk();
    final sdk = _razorpay;
    if (sdk == null) {
      onFailure?.call(_copy.donateFailedMessage);
      return;
    }
    if (order.keyId.trim().isEmpty || order.orderId.trim().isEmpty) {
      onFailure?.call(_copy.donateFailedMessage);
      return;
    }

    final checkoutName =
        order.checkoutName.trim().isNotEmpty ? order.checkoutName : 'Radio Udaan';
    final options = <String, dynamic>{
      'key': order.keyId,
      'amount': order.amountPaise,
      'currency': order.currency,
      'name': checkoutName,
      'description': 'Donation to Radio Udaan',
      'order_id': order.orderId,
      'prefill': {
        if (order.prefill.name.isNotEmpty) 'name': order.prefill.name,
        if (order.prefill.email.isNotEmpty) 'email': order.prefill.email,
        if (order.prefill.contact.isNotEmpty) 'contact': order.prefill.contact,
      },
      'theme': {'color': '#E87722'},
    };
    try {
      sdk.open(options);
    } catch (_) {
      onFailure?.call(_copy.donateFailedMessage);
    }
  }

  /// Returns true when the pending order is confirmed paid.
  /// Does not call [onFailure] when still unpaid (used for silent iOS resume polls).
  Future<bool> tryConfirmPendingPayment() async {
    final orderId = _pendingOrderId;
    if (orderId == null || orderId.isEmpty) return false;
    try {
      final result = await _api.verifyDonation(razorpayOrderId: orderId);
      if (result.success) {
        _pendingOrderId = null;
        onSuccess?.call(result);
        return true;
      }
    } catch (_) {
      // Network blip — caller may retry.
    }
    return false;
  }

  /// Polls Razorpay/WP until paid or attempts exhausted. Silent when still unpaid.
  Future<bool> pollConfirmPendingPayment({
    int attempts = 15,
    Duration gap = const Duration(seconds: 2),
  }) async {
    for (var i = 0; i < attempts; i++) {
      if (await tryConfirmPendingPayment()) return true;
      if (i < attempts - 1) {
        await Future<void>.delayed(gap);
      }
    }
    return false;
  }

  Future<void> verifyPendingPayment() async {
    final orderId = _pendingOrderId;
    if (orderId == null || orderId.isEmpty) {
      onFailure?.call(_copy.donateFailedMessage);
      return;
    }
    final ok = await pollConfirmPendingPayment(attempts: 3);
    if (!ok) {
      onFailure?.call(_copy.donateFailedMessage);
    }
  }

  Future<void> _verifyAndroid({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    try {
      final result = await _api.verifyDonation(
        razorpayOrderId: orderId,
        razorpayPaymentId: paymentId,
        razorpaySignature: signature,
      );
      if (result.success) {
        _pendingOrderId = null;
        onSuccess?.call(result);
      } else {
        onFailure?.call(_copy.donateFailedMessage);
      }
    } on ApiError catch (error) {
      onFailure?.call(error.message);
    } catch (_) {
      onFailure?.call(_copy.donateFailedMessage);
    }
  }

  void _onAndroidSuccess(PaymentSuccessResponse response) {
    final orderId = response.orderId ?? _pendingOrderId ?? '';
    final paymentId = response.paymentId ?? '';
    final signature = response.signature ?? '';
    if (orderId.isEmpty || paymentId.isEmpty || signature.isEmpty) {
      onFailure?.call(_copy.donateFailedMessage);
      return;
    }
    unawaited(
      _verifyAndroid(
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
      ),
    );
  }

  void _onAndroidError(PaymentFailureResponse response) {
    final message = response.message?.trim();
    onFailure?.call(
      message != null && message.isNotEmpty ? message : _copy.donateFailedMessage,
    );
  }

  void dispose() {
    if (_razorpay != null) {
      _razorpay!.clear();
      _razorpay = null;
    }
  }
}

bool isValidPan(String value) {
  final pan = value.toUpperCase().replaceAll(RegExp(r'\s+'), '');
  return RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(pan);
}

String normalizePan(String value) =>
    value.toUpperCase().replaceAll(RegExp(r'\s+'), '');

int? parseDonationAmountPaise(String rupeesText) {
  final cleaned = rupeesText.trim().replaceAll(',', '');
  if (cleaned.isEmpty) return null;
  final amount = double.tryParse(cleaned);
  if (amount == null || amount < 1) return null;
  return (amount * 100).round();
}
