import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists in-progress event registration field values per event id.
class RegistrationDraftStorage {
  RegistrationDraftStorage(this._prefs);

  static String _keyFor(int eventId) => 'registration_draft_$eventId';

  final SharedPreferences _prefs;

  static Future<RegistrationDraftStorage> create() async {
    return RegistrationDraftStorage(await SharedPreferences.getInstance());
  }

  Future<RegistrationDraft?> load(int eventId) async {
    final raw = _prefs.getString(_keyFor(eventId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final valuesRaw = map['values'];
      final labelsRaw = map['upload_labels'];
      if (valuesRaw is! Map) return null;
      return RegistrationDraft(
        values: _decodeValues(Map<String, dynamic>.from(valuesRaw)),
        uploadLabels: labelsRaw is Map
            ? Map<String, String>.from(
                labelsRaw.map(
                  (k, v) => MapEntry(k.toString(), v.toString()),
                ),
              )
            : const {},
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save({
    required int eventId,
    required Map<String, dynamic> values,
    required Map<String, String> uploadLabels,
  }) async {
    final sanitized = _encodeValues(values);
    if (sanitized.isEmpty && uploadLabels.isEmpty) {
      await clear(eventId);
      return;
    }
    await _prefs.setString(
      _keyFor(eventId),
      jsonEncode({
        'values': sanitized,
        'upload_labels': uploadLabels,
      }),
    );
  }

  Future<void> clear(int eventId) async {
    await _prefs.remove(_keyFor(eventId));
  }

  /// Removes all in-progress registration drafts (logout / account deletion).
  Future<void> clearAll() async {
    final prefix = 'registration_draft_';
    final keys = _prefs
        .getKeys()
        .where((k) => k.startsWith(prefix))
        .toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  static Map<String, dynamic> _encodeValues(Map<String, dynamic> values) {
    final out = <String, dynamic>{};
    for (final entry in values.entries) {
      final v = entry.value;
      if (v == null) continue;
      if (v is String) {
        if (v.trim().isEmpty) continue;
        out[entry.key] = v;
      } else if (v is bool || v is num) {
        out[entry.key] = v;
      } else if (v is List) {
        final list = v
            .map((e) => e?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
        if (list.isNotEmpty) out[entry.key] = list;
      } else if (v is Map) {
        final map = v.map((k, val) => MapEntry(k.toString(), val?.toString() ?? ''));
        if (map.values.any((s) => s.isNotEmpty)) out[entry.key] = map;
      }
    }
    return out;
  }

  static Map<String, dynamic> _decodeValues(Map<String, dynamic> raw) {
    final out = <String, dynamic>{};
    for (final entry in raw.entries) {
      final v = entry.value;
      if (v is bool || v is num || v is String) {
        out[entry.key] = v;
      } else if (v is List) {
        out[entry.key] = v.map((e) => e.toString()).toList();
      } else if (v is Map) {
        out[entry.key] = Map<String, dynamic>.from(
          v.map((k, val) => MapEntry(k.toString(), val)),
        );
      }
    }
    return out;
  }
}

class RegistrationDraft {
  const RegistrationDraft({
    required this.values,
    required this.uploadLabels,
  });

  final Map<String, dynamic> values;
  final Map<String, String> uploadLabels;
}
