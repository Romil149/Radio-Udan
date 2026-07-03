import 'app_copy_defaults.dart';

/// Live tab content from `GET /config` → `live_radio`.
class LiveRadioConfig {
  const LiveRadioConfig({
    required this.showTitle,
    required this.showSubtitle,
    required this.heroImageUrl,
    required this.defaultShowTitle,
    required this.defaultShowSubtitle,
    required this.defaultHeroImageUrl,
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
    final showTitle = pick('show_title', f.showTitle);
    final showSubtitle = pick('show_subtitle', f.showSubtitle);
    final heroImageUrl = pick('hero_image_url', '');

    return LiveRadioConfig(
      showTitle: showTitle,
      showSubtitle: showSubtitle,
      heroImageUrl: heroImageUrl,
      defaultShowTitle: pick('default_show_title', showTitle),
      defaultShowSubtitle: pick('default_show_subtitle', showSubtitle),
      defaultHeroImageUrl: pick('default_hero_image_url', heroImageUrl),
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
    showTitle: appCopyDefaults['radio_show_title']!,
    showSubtitle: appCopyDefaults['radio_show_subtitle']!,
    heroImageUrl: '',
    defaultShowTitle: appCopyDefaults['radio_show_title']!,
    defaultShowSubtitle: appCopyDefaults['radio_show_subtitle']!,
    defaultHeroImageUrl: '',
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

  final String showTitle;
  final String showSubtitle;
  final String heroImageUrl;
  final String defaultShowTitle;
  final String defaultShowSubtitle;
  final String defaultHeroImageUrl;
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
  bool get hasDefaultHeroImage => defaultHeroImageUrl.isNotEmpty;
  bool get hasWhatsappUrl => whatsappUrl.isNotEmpty;

  /// Admin Live radio defaults (between scheduled shows).
  LiveRadioConfig get adminDefaults => LiveRadioConfig(
        showTitle: defaultShowTitle,
        showSubtitle: defaultShowSubtitle,
        heroImageUrl: defaultHeroImageUrl,
        defaultShowTitle: defaultShowTitle,
        defaultShowSubtitle: defaultShowSubtitle,
        defaultHeroImageUrl: defaultHeroImageUrl,
        fromSchedule: false,
        scheduledShowId: '',
        whatsappUrl: whatsappUrl,
        whatsappLabel: whatsappLabel,
        shareLabel: shareLabel,
        shareText: shareText,
        showWhatsapp: showWhatsapp,
        showShare: showShare,
        showVolume: showVolume,
        menuAction: menuAction,
        profileAction: profileAction,
      );
}
