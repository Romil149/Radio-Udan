import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/remote_config.dart';

/// On-device cache for `GET /config` — instant theme/branding on cold start.
class ConfigCacheStorage {
  ConfigCacheStorage(this._prefs);

  static const _jsonKey = 'remote_config_json';
  static const _fetchedAtKey = 'remote_config_fetched_at_ms';

  /// Prefer cache for this long; refresh from network in background after.
  static const Duration freshFor = Duration(hours: 6);

  final SharedPreferences _prefs;

  static Future<ConfigCacheStorage> create() async {
    return ConfigCacheStorage(await SharedPreferences.getInstance());
  }

  Future<RemoteConfig?> load() async {
    final raw = _prefs.getString(_jsonKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return RemoteConfig.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveJson(Map<String, dynamic> json) async {
    await _prefs.setString(_jsonKey, jsonEncode(json));
    await _prefs.setInt(
      _fetchedAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  bool get shouldBackgroundRefresh {
    final ms = _prefs.getInt(_fetchedAtKey);
    if (ms == null) return true;
    final age = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(ms),
    );
    return age > freshFor;
  }

}
