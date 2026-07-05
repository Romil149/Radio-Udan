import 'app_copy_defaults.dart';

/// Live tab chrome from `GET /config` → `live_radio` (buttons, fallback hero).
/// Song title/artist/art load from AzuraCast via [nowPlayingApiUrl] on the app.
class LiveRadioConfig {
  const LiveRadioConfig({
    required this.heroImageUrl,
    required this.fromSchedule,
    required this.scheduledShowId,
    required this.whatsappUrl,
    required this.whatsappLabel,
    required this.shareLabel,
    required this.shareText,
    required this.showWhatsapp,
    required this.showShare,
    required this.showVolume,
    required this.menuAction,
    required this.profileAction,
  });

  factory LiveRadioConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return LiveRadioConfig.fallback;
    }

    String pick(String key, String fallback) {
      final v = json[key]?.toString().trim() ?? '';
      return v.isNotEmpty ? v : fallback;
    }

    final f = LiveRadioConfig.fallback;

    return LiveRadioConfig(
      heroImageUrl: pick('hero_image_url', ''),
      fromSchedule: json['from_schedule'] == true,
      scheduledShowId: pick('scheduled_show_id', ''),
      whatsappUrl: pick('whatsapp_url', f.whatsappUrl),
      whatsappLabel: pick('whatsapp_label', f.whatsappLabel),
      shareLabel: pick('share_label', f.shareLabel),
      shareText: pick('share_text', f.shareText),
      showWhatsapp: json['show_whatsapp'] != false,
      showShare: json['show_share'] != false,
      showVolume: json['show_volume'] != false,
      menuAction: pick('menu_action', 'more'),
      profileAction: pick('profile_action', 'more'),
    );
  }

  static final LiveRadioConfig fallback = LiveRadioConfig(
    heroImageUrl: '',
    fromSchedule: false,
    scheduledShowId: '',
    whatsappUrl: appCopyDefaults['radio_whatsapp_url_fallback']!,
    whatsappLabel: appCopyDefaults['join_whats_app_channel']!,
    shareLabel: appCopyDefaults['share']!,
    shareText: appCopyDefaults['radio_share_text_fallback']!,
    showWhatsapp: true,
    showShare: true,
    showVolume: true,
    menuAction: 'more',
    profileAction: 'more',
  );

  final String heroImageUrl;
  final bool fromSchedule;
  final String scheduledShowId;
  final String whatsappUrl;
  final String whatsappLabel;
  final String shareLabel;
  final String shareText;
  final bool showWhatsapp;
  final bool showShare;
  final bool showVolume;
  final String menuAction;
  final String profileAction;

  bool get hasHeroImage => heroImageUrl.isNotEmpty;
  bool get hasWhatsappUrl => whatsappUrl.isNotEmpty;
}
