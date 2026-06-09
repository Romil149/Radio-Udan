/// Local accessibility and notification preferences (device storage).
class AppUserSettings {
  const AppUserSettings({
    this.highContrast = false,
    this.textScale = 1.0,
    this.boldText = false,
    this.reduceMotion = false,
    this.notifyLiveBroadcasts = true,
    this.notifyEventAlerts = true,
    this.notifyPromotions = false,
    this.apiBaseUrlOverride,
  });

  factory AppUserSettings.fromPrefs(Map<String, Object?> prefs) {
    return AppUserSettings(
      highContrast: prefs['high_contrast'] == true,
      textScale: (prefs['text_scale'] as num?)?.toDouble() ?? 1.0,
      boldText: prefs['bold_text'] == true,
      reduceMotion: prefs['reduce_motion'] == true,
      notifyLiveBroadcasts: prefs['notify_live'] != false,
      notifyEventAlerts: prefs['notify_events'] != false,
      notifyPromotions: prefs['notify_promotions'] == true,
      apiBaseUrlOverride: prefs['api_base_url_override']?.toString(),
    );
  }

  final bool highContrast;
  final double textScale;
  final bool boldText;
  final bool reduceMotion;
  final bool notifyLiveBroadcasts;
  final bool notifyEventAlerts;
  final bool notifyPromotions;
  final String? apiBaseUrlOverride;

  AppUserSettings copyWith({
    bool? highContrast,
    double? textScale,
    bool? boldText,
    bool? reduceMotion,
    bool? notifyLiveBroadcasts,
    bool? notifyEventAlerts,
    bool? notifyPromotions,
    String? apiBaseUrlOverride,
  }) {
    return AppUserSettings(
      highContrast: highContrast ?? this.highContrast,
      textScale: textScale ?? this.textScale,
      boldText: boldText ?? this.boldText,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      notifyLiveBroadcasts:
          notifyLiveBroadcasts ?? this.notifyLiveBroadcasts,
      notifyEventAlerts: notifyEventAlerts ?? this.notifyEventAlerts,
      notifyPromotions: notifyPromotions ?? this.notifyPromotions,
      apiBaseUrlOverride: apiBaseUrlOverride ?? this.apiBaseUrlOverride,
    );
  }

  Map<String, Object?> toPrefs() => {
        'high_contrast': highContrast,
        'text_scale': textScale,
        'bold_text': boldText,
        'reduce_motion': reduceMotion,
        'notify_live': notifyLiveBroadcasts,
        'notify_events': notifyEventAlerts,
        'notify_promotions': notifyPromotions,
        if (apiBaseUrlOverride != null && apiBaseUrlOverride!.isNotEmpty)
          'api_base_url_override': apiBaseUrlOverride,
      };
}
