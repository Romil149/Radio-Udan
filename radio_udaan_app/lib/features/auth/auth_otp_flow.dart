import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/otp_purpose.dart';
import '../../core/network/dio_exception_mapper.dart';
import '../../core/providers/app_providers.dart';
import '../../core/router/app_router.dart';

/// Requests login OTP and opens the verify screen.
Future<String?> requestLoginOtpAndOpenVerify(
  BuildContext context,
  WidgetRef ref,
  String phoneE164,
) async {
  try {
    final result = await ref.read(radioudaanApiProvider).requestOtp(
          phoneE164,
          purpose: OtpPurpose.login,
        );
    if (!context.mounted) return null;
    await context.push(
      '/otp',
      extra: OtpRouteArgs(
        requestId: result.requestId,
        phoneE164: phoneE164,
        resendAfterSec: result.resendAfterSec,
        devOtp: result.devOtp,
        purpose: OtpPurpose.login,
      ),
    );
    return null;
  } catch (e) {
    return parseApiError(e).message;
  }
}
