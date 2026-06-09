/// OTP flow purpose sent to `POST /auth/otp/*` (matches WordPress plugin).
enum OtpPurpose {
  login('login'),
  verifyPhone('verify_phone'),
  resetPassword('reset_password');

  const OtpPurpose(this.apiValue);

  final String apiValue;

  static OtpPurpose? tryParse(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final p in OtpPurpose.values) {
      if (p.apiValue == value) return p;
    }
    return null;
  }
}
