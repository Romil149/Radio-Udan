import 'dart:async';

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

/// Platform checkout: native Razorpay on Android, payment link on iOS.
class DonateRazorpayService {
  DonateRazorpayService({
    required RadioUdaanApi api,
    required AppCopy copy,
  })  : _api = api,
        _copy = copy {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onAndroidSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onAndroidError);
    }
  }

  final RadioUdaanApi _api;
  final AppCopy _copy;
  Razorpay? _razorpay;

  DonationPaymentSuccess? onSuccess;
  DonationPaymentFailure? onFailure;

  String? _pendingOrderId;

  bool get usesPaymentLink =>
      kIsWeb || defaultTargetPlatform == TargetPlatform.iOS;

  String? get pendingOrderId => _pendingOrderId;

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
      if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        onFailure?.call(_copy.donateFailedMessage);
      }
      return;
    }

    final checkoutName =
        order.checkoutName.trim().isNotEmpty ? order.checkoutName : 'Radio Udaan';
    final options = <String, dynamic>{
      'key': order.keyId,
      'amount': order.amountPaise,
      'currency': order.currency,
      'name': checkoutName,
      'order_id': order.orderId,
      'prefill': {
        'name': order.prefill.name,
        'email': order.prefill.email,
        'contact': order.prefill.contact,
      },
    };
    _razorpay?.open(options);
  }

  Future<void> verifyPendingPayment() async {
    final orderId = _pendingOrderId;
    if (orderId == null || orderId.isEmpty) {
      onFailure?.call(_copy.donateFailedMessage);
      return;
    }
    try {
      final result = await _api.verifyDonation(razorpayOrderId: orderId);
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
      _razorpay!
        ..clear();
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
