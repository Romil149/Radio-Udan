import 'otp_purpose.dart';

/// Response from `POST /auth/otp/request`.
class OtpRequestResult {
  const OtpRequestResult({
    required this.requestId,
    required this.expiresInSec,
    required this.resendAfterSec,
    this.devOtp,
    this.purpose,
  });

  final String requestId;
  final int expiresInSec;
  final int resendAfterSec;

  /// Present only when the server runs in development OTP mode.
  final String? devOtp;
  final OtpPurpose? purpose;
}
