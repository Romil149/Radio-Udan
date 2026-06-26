import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/radioudaan_api.dart';
import '../config/app_env.dart';
import '../config/remote_config.dart';
import '../models/auth_session.dart';
import '../providers/app_providers.dart';
import '../push/push_notification_service.dart';
import '../providers/app_settings_provider.dart';
import '../storage/config_cache_storage.dart';
import '../storage/settings_storage.dart';

/// Cold-start: cached config first, then parallel network refresh + session check.
class AppBootstrap {
  AppBootstrap(this._ref);

  final Ref _ref;

  void _applyConfig(RemoteConfig config, {String? baseOverride}) {
    _ref.read(remoteConfigProvider.notifier).state = config;
    if (baseOverride == null && config.apiBaseUrl.isNotEmpty) {
      _ref.read(apiBaseUrlProvider.notifier).state = config.apiBaseUrl;
    }
  }

  Future<void> _syncNotificationPreferences(RadioUdaanApi api) async {
    try {
      final prefs = await api.fetchNotificationPreferences();
      final current = _ref.read(appSettingsProvider);
      await _ref.read(appSettingsProvider.notifier).save(
            current.copyWith(
              notifyLiveBroadcasts: prefs.liveBroadcastsEnabled,
              notifyEventAlerts: prefs.eventsEnabled,
              notifyPromotions: prefs.promotionsEnabled,
            ),
          );
    } catch (_) {
      // Server prefs are optional at bootstrap.
    }
  }

  void _applyUser(AuthSession? session, {required String? token}) {
    if (session == null) {
      _ref.read(authUserProvider.notifier).state = null;
      _ref.read(authPhoneProvider.notifier).state = null;
      return;
    }

    final withToken = session.token.isNotEmpty
        ? session
        : session.copyWith(token: token ?? '');
    _ref.read(authUserProvider.notifier).state = withToken;
    if (withToken.phoneE164.isNotEmpty) {
      _ref.read(authPhoneProvider.notifier).state = withToken.phoneE164;
    }
  }

  Future<BootstrapResult> run() async {
    final settings = await SettingsStorage.create();
    await _ref.read(appSettingsProvider.notifier).load();
    final configCache = await ConfigCacheStorage.create();
    final tokenStore = _ref.read(tokenStorageProvider);
    final storedToken = await tokenStore.readToken();

    var baseUrl = settings.apiBaseUrlOverride ?? AppEnv.bootstrapApiBaseUrl;
    _ref.read(apiBaseUrlProvider.notifier).state = baseUrl;

    final cached = await configCache.load();
    if (cached != null) {
      _applyConfig(cached, baseOverride: settings.apiBaseUrlOverride);
    }

    RemoteConfig? config = cached;
    final hasToken = storedToken != null && storedToken.isNotEmpty;

    // Restore token only; verification flags come from GET /auth/me (never assumed).
    if (hasToken) {
      _ref.read(authTokenProvider.notifier).state = storedToken;
    }

    var sessionValidated = false;

    try {
      final client = ApiClient(
        baseUrl: baseUrl,
        bearerToken: hasToken ? storedToken : null,
      );
      final api = RadioUdaanApi(client);

      Future<RemoteConfig> loadConfig() async {
        final json = await api.fetchConfigJson();
        await configCache.saveJson(json);
        return RemoteConfig.fromJson(json);
      }

      Future<void> validateSession() async {
        final me = await api.fetchMe(bearerToken: storedToken);
        if (me == null) {
          await tokenStore.clear();
          _ref.read(authTokenProvider.notifier).state = null;
          _applyUser(null, token: null);
        } else {
          sessionValidated = true;
          final session = me.copyWith(token: storedToken ?? me.token);
          _applyUser(session, token: storedToken);
          await tokenStore.saveSession(
            token: session.token,
            phoneE164: session.phoneE164,
            email: session.email,
            name: session.name,
          );
          await _syncNotificationPreferences(api);
        }
      }

      if (hasToken) {
        final results = await Future.wait([
          loadConfig(),
          validateSession(),
        ]);
        config = results[0] as RemoteConfig;
      } else {
        config = await loadConfig();
      }

      if (settings.apiBaseUrlOverride == null && config.apiBaseUrl.isNotEmpty) {
        baseUrl = config.apiBaseUrl;
        _ref.read(apiBaseUrlProvider.notifier).state = baseUrl;
      }
      _applyConfig(config, baseOverride: settings.apiBaseUrlOverride);
    } catch (_) {
      // Fail closed: never keep a bearer token we could not validate on cold start.
      if (hasToken && !sessionValidated) {
        await tokenStore.clear();
        _ref.read(authTokenProvider.notifier).state = null;
        _applyUser(null, token: null);
      }
    }

    final loggedIn = _ref.read(authTokenProvider) != null;
    final push = _ref.read(pushNotificationServiceProvider);
    await push.initialize();
    if (loggedIn && settings.notificationPermissionPromptSeen) {
      await push.registerDeviceToken();
    }

    return BootstrapResult(
      configLoaded: config != null,
      isLoggedIn: loggedIn,
    );
  }
}

class BootstrapResult {
  const BootstrapResult({
    required this.configLoaded,
    required this.isLoggedIn,
  });

  final bool configLoaded;
  final bool isLoggedIn;
}

final bootstrapProvider = FutureProvider<BootstrapResult>((ref) async {
  return AppBootstrap(ref).run();
});
