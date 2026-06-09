import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/radioudaan_api.dart';
import '../config/app_branding.dart';
import '../config/app_env.dart';
import '../config/live_radio_config.dart';
import '../config/remote_config.dart';
import '../models/auth_session.dart';
import '../storage/settings_storage.dart';
import '../storage/token_storage.dart';

final settingsStorageProvider = FutureProvider<SettingsStorage>((ref) async {
  return SettingsStorage.create();
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

/// Effective API base: override → remote config → bootstrap default.
final apiBaseUrlProvider = StateProvider<String>((ref) {
  return AppEnv.bootstrapApiBaseUrl;
});

final remoteConfigProvider = StateProvider<RemoteConfig?>((ref) => null);

final appBrandingProvider = Provider<AppBranding>((ref) {
  return ref.watch(remoteConfigProvider)?.branding ?? AppBranding.defaults;
});

final appCopyProvider = Provider<AppCopy>((ref) {
  return ref.watch(remoteConfigProvider)?.copy ?? AppCopy.fallback;
});

final liveRadioProvider = Provider<LiveRadioConfig>((ref) {
  return ref.watch(remoteConfigProvider)?.liveRadio ?? LiveRadioConfig.fallback;
});

/// Main shell tab index: 0 Live, 1 Library, 2 Events, 3 More.
final mainShellTabIndexProvider = StateProvider<int>((ref) => 0);

final authTokenProvider = StateProvider<String?>((ref) => null);

/// Cached profile for routing (phone/email verification) and More tab.
final authUserProvider = StateProvider<AuthSession?>((ref) => null);

/// @deprecated Prefer [authUserProvider] phone; kept for gradual migration.
final authPhoneProvider = StateProvider<String?>((ref) => null);

final apiClientProvider = Provider<ApiClient>((ref) {
  ref.keepAlive();
  final base = ref.watch(apiBaseUrlProvider);
  final token = ref.watch(authTokenProvider);
  return ApiClient(baseUrl: base, bearerToken: token);
});

final radioudaanApiProvider = Provider<RadioUdaanApi>((ref) {
  return RadioUdaanApi(ref.watch(apiClientProvider));
});
