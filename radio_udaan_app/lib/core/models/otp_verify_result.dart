import 'auth_session.dart';

/// Result of `POST /auth/otp/verify` (session or password-reset continuation).
class OtpVerifyResult {
  const OtpVerifyResult({
    this.session,
    this.resetReady = false,
    this.phoneE164,
    this.purpose,
  });

  factory OtpVerifyResult.fromJson(Map<String, dynamic> json) {
    final isReset = json['reset_ready'] == true ||
        (json['status'] == 'otp_verified' &&
            json['purpose'] == 'reset_password');
    if (isReset) {
      return OtpVerifyResult(
        resetReady: true,
        phoneE164: json['phone_e164']?.toString(),
        purpose: json['purpose']?.toString(),
      );
    }

    if (json['token'] != null || json['user'] != null) {
      return OtpVerifyResult(
        session: AuthSession.fromJson(json),
        purpose: json['purpose']?.toString(),
      );
    }

    return const OtpVerifyResult();
  }

  final AuthSession? session;
  final bool resetReady;
  final String? phoneE164;
  final String? purpose;
}
