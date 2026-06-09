/// Bearer session returned after login, OTP verify, or `/auth/me`.
class AuthSession {
  const AuthSession({
    required this.token,
    required this.phoneE164,
    this.userId,
    this.name,
    this.email,
    this.phoneVerified = false,
    this.emailVerified = false,
    this.status,
    this.expiresAt,
    this.avatarUrl,
  });

  factory AuthSession.fromJson(
    Map<String, dynamic> json, {
    String fallbackToken = '',
  }) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return AuthSession(
      token: json['token']?.toString() ?? fallbackToken,
      expiresAt: json['expires_at']?.toString(),
      userId: _parseInt(user['id']),
      name: user['name']?.toString(),
      email: user['email']?.toString(),
      phoneE164: user['phone_e164']?.toString() ?? '',
      phoneVerified: user['phone_verified'] == true,
      emailVerified: user['email_verified'] == true,
      status: user['status']?.toString(),
      avatarUrl: user['avatar_url']?.toString(),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  final String token;
  final String phoneE164;
  final int? userId;
  final String? name;
  final String? email;
  final bool phoneVerified;
  final bool emailVerified;
  final String? status;
  final String? expiresAt;
  final String? avatarUrl;

  bool get hasToken => token.isNotEmpty;

  AuthSession copyWith({
    String? token,
    String? phoneE164,
    int? userId,
    String? name,
    String? email,
    bool? phoneVerified,
    bool? emailVerified,
    String? status,
    String? expiresAt,
    String? avatarUrl,
  }) {
    return AuthSession(
      token: token ?? this.token,
      phoneE164: phoneE164 ?? this.phoneE164,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      emailVerified: emailVerified ?? this.emailVerified,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

/// Result of `PATCH /auth/me` including whether a verification email was sent.
class ProfileUpdateResult {
  const ProfileUpdateResult({
    required this.session,
    required this.emailVerificationSent,
  });

  final AuthSession session;
  final bool emailVerificationSent;
}
