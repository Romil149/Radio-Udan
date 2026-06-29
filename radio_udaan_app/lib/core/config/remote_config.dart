import 'app_branding.dart';
import 'info_hub_config.dart';
import 'legal_pages_config.dart';
import 'live_radio_config.dart';

/// Public payload from `GET /config`.
class RemoteConfig {
  const RemoteConfig({
    required this.apiVersion,
    required this.apiBaseUrl,
    required this.siteUrl,
    required this.streamUrl,
    required this.uploadMaxFileMb,
    required this.otpResendDelaySec,
    required this.inAppLibraryPlayback,
    required this.branding,
    required this.copy,
    required this.liveRadio,
    required this.authPolicy,
    this.privacyPolicyUrl,
    this.termsUrl,
    this.aboutUrl,
    this.contactUrl,
    this.appStoreUrl,
    this.playStoreUrl,
    this.legalPages = const LegalPagesConfig(),
    this.support = const SupportConfig(),
    this.infoHub = const InfoHubConfig(),
    this.notificationDefaults = const NotificationPreferenceDefaults(),
  });

  factory RemoteConfig.fromJson(Map<String, dynamic> json) {
    final upload = json['upload_constraints'] as Map<String, dynamic>? ?? {};
    final otp = json['otp_policy'] as Map<String, dynamic>? ?? {};
    final features = json['features'] as Map<String, dynamic>? ?? {};
    final auth = json['auth_policy'] as Map<String, dynamic>? ?? {};

    return RemoteConfig(
      apiVersion: json['api_version']?.toString() ?? '',
      apiBaseUrl: json['api_base_url']?.toString() ?? '',
      siteUrl: json['site_url']?.toString() ?? '',
      streamUrl: json['stream_url']?.toString() ?? '',
      uploadMaxFileMb: (upload['max_file_mb'] as num?)?.toInt() ?? 10,
      otpResendDelaySec: (otp['resend_delay_sec'] as num?)?.toInt() ?? 60,
      inAppLibraryPlayback: features['in_app_library_playback'] == true,
      branding: AppBranding.fromJson(
        json['branding'] as Map<String, dynamic>?,
      ),
      copy: AppCopy.fromJson(json['copy'] as Map<String, dynamic>?),
      liveRadio: LiveRadioConfig.fromJson(
        json['live_radio'] as Map<String, dynamic>?,
      ),
      authPolicy: AuthPolicy.fromJson(auth),
      privacyPolicyUrl: _parseOptionalUrl(json['privacy_policy_url']),
      termsUrl: _parseOptionalUrl(json['terms_url']),
      aboutUrl: _parseOptionalUrl(json['about_url']),
      contactUrl: _parseOptionalUrl(json['contact_url']),
      appStoreUrl: _parseOptionalUrl(json['app_store_url']),
      playStoreUrl: _parseOptionalUrl(json['play_store_url']),
      legalPages: LegalPagesConfig.fromJson(
        json['legal_pages'] as Map<String, dynamic>?,
      ),
      support: SupportConfig.fromJson(
        json['support'] as Map<String, dynamic>?,
      ),
      infoHub: InfoHubConfig.fromJson(
        json['info_hub'] as Map<String, dynamic>?,
      ),
      notificationDefaults: NotificationPreferenceDefaults.fromJson(
        json['notification_preferences'] as Map<String, dynamic>?,
      ),
    );
  }

  static String? _parseOptionalUrl(dynamic value) {
    final url = value?.toString().trim() ?? '';
    if (url.isEmpty) return null;
    return url;
  }

  final String apiVersion;
  final String apiBaseUrl;
  final String siteUrl;
  final String streamUrl;
  final int uploadMaxFileMb;
  final int otpResendDelaySec;
  final bool inAppLibraryPlayback;
  final AppBranding branding;
  final AppCopy copy;
  final LiveRadioConfig liveRadio;
  final AuthPolicy authPolicy;
  final String? privacyPolicyUrl;
  final String? termsUrl;
  final String? aboutUrl;
  final String? contactUrl;
  final String? appStoreUrl;
  final String? playStoreUrl;
  final LegalPagesConfig legalPages;
  final SupportConfig support;
  final InfoHubConfig infoHub;
  final NotificationPreferenceDefaults notificationDefaults;
}

/// Support contacts from `GET /config` → `support`.
class SupportConfig {
  const SupportConfig({this.helplinePhone, this.email});

  factory SupportConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return const SupportConfig();
    return SupportConfig(
      helplinePhone: json['helpline_phone']?.toString().trim(),
      email: json['email']?.toString().trim(),
    );
  }

  final String? helplinePhone;
  final String? email;
}

/// Default notification toggles from WordPress (merged with device prefs).
class NotificationPreferenceDefaults {
  const NotificationPreferenceDefaults({
    this.eventsEnabled = true,
    this.libraryEnabled = true,
    this.promotionsEnabled = false,
  });

  factory NotificationPreferenceDefaults.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return const NotificationPreferenceDefaults();
    }
    return NotificationPreferenceDefaults(
      eventsEnabled: json['events_enabled'] != false,
      libraryEnabled: json['library_enabled'] != false,
      promotionsEnabled: json['promotions_enabled'] == true,
    );
  }

  final bool eventsEnabled;
  final bool libraryEnabled;
  final bool promotionsEnabled;
}

/// Registration and login rules from WordPress `auth_policy` in `/config`.
class AuthPolicy {
  const AuthPolicy({
    this.requireEmailVerification = false,
    this.requireUniqueEmail = true,
    this.passwordMinLength = 8,
  });

  factory AuthPolicy.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return const AuthPolicy();
    }
    return AuthPolicy(
      requireEmailVerification: json['require_email_verification'] == true,
      requireUniqueEmail: json['require_unique_email'] != false,
      passwordMinLength: (json['password_min_length'] as num?)?.toInt() ?? 8,
    );
  }

  final bool requireEmailVerification;
  final bool requireUniqueEmail;
  final int passwordMinLength;
}
