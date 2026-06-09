/// Response from `POST /auth/register` before phone OTP completes.
class RegisterResult {
  const RegisterResult({
    required this.needsPhoneVerification,
    required this.phoneE164,
    this.status,
    this.user,
  });

  factory RegisterResult.fromJson(Map<String, dynamic> json) {
    return RegisterResult(
      needsPhoneVerification:
          json['needs_phone_verification'] == true ||
              json['status']?.toString() == 'pending_phone_verification',
      phoneE164: json['phone_e164']?.toString() ?? '',
      status: json['status']?.toString(),
      user: json['user'] as Map<String, dynamic>?,
    );
  }

  final bool needsPhoneVerification;
  final String phoneE164;
  final String? status;
  final Map<String, dynamic>? user;
}
