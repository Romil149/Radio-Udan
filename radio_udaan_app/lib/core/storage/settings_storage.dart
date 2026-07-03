import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user_settings.dart';

/// Device preferences: accessibility, notifications, optional API override.
class SettingsStorage {
  SettingsStorage(this._prefs);

  static const _prefix = 'ru_settings_';

  final SharedPreferences _prefs;

  static Future<SettingsStorage> create() async {
    return SettingsStorage(await SharedPreferences.getInstance());
  }

  AppUserSettings load() {
    return AppUserSettings(
      highContrast: _prefs.getBool('${_prefix}high_contrast') ?? false,
      textScale: _prefs.getDouble('${_prefix}text_scale') ?? 1.0,
      boldText: _prefs.getBool('${_prefix}bold_text') ?? false,
      reduceMotion: _prefs.getBool('${_prefix}reduce_motion') ?? false,
      notifyLiveBroadcasts:
          _prefs.getBool('${_prefix}notify_live') ?? true,
      notifyEventAlerts: _prefs.getBool('${_prefix}notify_events') ?? true,
      notifyPromotions: _prefs.getBool('${_prefix}notify_promotions') ?? false,
      apiBaseUrlOverride: _prefs.getString('api_base_url_override'),
    );
  }

  Future<void> save(AppUserSettings settings) async {
    await _prefs.setBool('${_prefix}high_contrast', settings.highContrast);
    await _prefs.setDouble('${_prefix}text_scale', settings.textScale);
    await _prefs.setBool('${_prefix}bold_text', settings.boldText);
    await _prefs.setBool('${_prefix}reduce_motion', settings.reduceMotion);
    await _prefs.setBool(
      '${_prefix}notify_live',
      settings.notifyLiveBroadcasts,
    );
    await _prefs.setBool(
      '${_prefix}notify_events',
      settings.notifyEventAlerts,
    );
    await _prefs.setBool(
      '${_prefix}notify_promotions',
      settings.notifyPromotions,
    );
    final override = settings.apiBaseUrlOverride;
    if (override == null || override.isEmpty) {
      await _prefs.remove('api_base_url_override');
    } else {
      await _prefs.setString('api_base_url_override', override);
    }
  }

  String? get apiBaseUrlOverride => _prefs.getString('api_base_url_override');

  Future<void> setApiBaseUrlOverride(String? url) async {
    if (url == null || url.isEmpty) {
      await _prefs.remove('api_base_url_override');
    } else {
      await _prefs.setString('api_base_url_override', url);
    }
  }
}
