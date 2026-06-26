import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user_settings.dart';
import 'app_providers.dart';

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppUserSettings>((ref) {
  return AppSettingsNotifier(ref);
});

class AppSettingsNotifier extends StateNotifier<AppUserSettings> {
  AppSettingsNotifier(this._ref) : super(const AppUserSettings());

  final Ref _ref;

  Future<void> load() async {
    final storage = await _ref.read(settingsStorageProvider.future);
    state = storage.load();
  }

  Future<void> save(AppUserSettings next) async {
    state = next;
    final storage = await _ref.read(settingsStorageProvider.future);
    await storage.save(next);
  }

  /// Persists accessibility fields immediately without touching notifications.
  Future<void> saveAccessibility(AppUserSettings next) async {
    final merged = state.copyWith(
      highContrast: next.highContrast,
      textScale: next.textScale,
      boldText: next.boldText,
      reduceMotion: next.reduceMotion,
    );
    state = merged;
    final storage = await _ref.read(settingsStorageProvider.future);
    await storage.save(merged);
  }

  Future<void> patch(AppUserSettings Function(AppUserSettings) update) async {
    await save(update(state));
  }

  /// Apply settings in memory for live preview (does not persist).
  void preview(AppUserSettings next) {
    state = next;
  }
}
