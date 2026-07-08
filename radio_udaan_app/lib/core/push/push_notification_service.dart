import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../features/more/notifications_screen.dart';
import '../../firebase_options.dart';
import '../api/radioudaan_api.dart';
import '../providers/app_providers.dart';
import '../router/app_router.dart';
import '../router/whats_new_deep_link.dart';

/// Android notification channel — must match WP FCM `channel_id`.
const kPushAndroidChannelId = 'radioudaan_alerts';
const kPushAndroidChannelName = 'Radio Udaan Alerts';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Outcome of a push registration attempt (Settings + debug).
enum PushRegistrationResult {
  success,
  permissionDenied,
  tokenUnavailable,
  apiFailed,
  unavailable,
}

/// Registers FCM token and shows foreground notifications.
class PushNotificationService {
  PushNotificationService(this._api);

  static const Duration _startupTimeout = Duration(seconds: 8);
  static const Duration _iosStartupTimeout = Duration(seconds: 30);

  final RadioUdaanApi _api;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _tokenRefreshListening = false;
  static bool _backgroundHandlerRegistered = false;

  /// Firebase + FCM auto-init only — does not wait for local notification setup.
  Future<bool> _ensureMessagingCore() async {
    if (kIsWeb) return false;
    if (!await ensureFirebase()) return false;
    try {
      await FirebaseMessaging.instance.setAutoInitEnabled(true);
    } catch (e) {
      debugPrint('FCM auto-init failed: $e');
    }
    return true;
  }

  static Future<bool> ensureFirebase() async {
    if (kIsWeb) return false;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      return true;
    } catch (e) {
      debugPrint('Firebase init skipped: $e');
      return false;
    }
  }

  /// Background sync after login, cold start, or app resume. Never blocks UI.
  Future<void> syncForLoggedInUser() async {
    if (kIsWeb) return;
    if (!await _ensureMessagingCore()) return;

    // Listeners / local notifications — best effort, do not block token upload.
    unawaited(
      initialize().timeout(
        Platform.isIOS ? _iosStartupTimeout : _startupTimeout,
        onTimeout: () {},
      ),
    );

    var result = await _ensureRegisteredDetailed();
    if (Platform.isIOS && result == PushRegistrationResult.tokenUnavailable) {
      await Future<void>.delayed(const Duration(seconds: 15));
      result = await _ensureRegisteredDetailed();
    }

    if (kDebugMode) {
      debugPrint('Push background registration result: $result');
    }
  }

  /// Explicit registration (Settings button) — returns outcome for user feedback.
  Future<PushRegistrationResult> syncForLoggedInUserDetailed() async {
    if (kIsWeb) return PushRegistrationResult.unavailable;

    final initTimeout =
        Platform.isIOS ? _iosStartupTimeout : _startupTimeout;
    try {
      await initialize().timeout(initTimeout);
    } on TimeoutException {
      debugPrint('Push initialize timed out; continuing with token registration');
    } catch (e) {
      debugPrint('Push initialize failed; continuing: $e');
    }

    if (!await _ensureMessagingCore()) {
      return PushRegistrationResult.unavailable;
    }

    var result = await _ensureRegisteredDetailed();
    if (result == PushRegistrationResult.success) {
      return result;
    }

    // iOS APNs/FCM can lag after grant — retry once after a short wait.
    if (Platform.isIOS && result == PushRegistrationResult.tokenUnavailable) {
      await Future<void>.delayed(const Duration(seconds: 15));
      result = await _ensureRegisteredDetailed();
    }

    if (kDebugMode) {
      debugPrint('Push registration result: $result');
    }
    return result;
  }

  /// Runs after home/login is visible — never block cold start on FCM/APNs.
  Future<void> startupAfterBootstrap({required bool loggedIn}) async {
    if (!loggedIn) return;
    await syncForLoggedInUser();
  }

  Future<PushRegistrationResult> _ensureRegisteredDetailed() async {
    if (!await _ensureMessagingCore()) {
      return PushRegistrationResult.unavailable;
    }

    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        await requestSystemPermission();
      } else if (Platform.isAndroid) {
        final androidStatus = await Permission.notification.status;
        if (!androidStatus.isGranted && !androidStatus.isLimited) {
          await Permission.notification.request();
        }
      }
    } catch (e) {
      debugPrint('Push permission check failed: $e');
    }

    if (!await hasSystemPermission()) {
      return PushRegistrationResult.permissionDenied;
    }
    return registerDeviceTokenDetailed(attempts: Platform.isIOS ? 6 : 4);
  }

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    if (!await ensureFirebase()) return;

    if (!_backgroundHandlerRegistered) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _backgroundHandlerRegistered = true;
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              kPushAndroidChannelId,
              kPushAndroidChannelName,
              description: 'Live broadcasts, events, and updates',
              importance: Importance.high,
            ),
          );
    }

    if (Platform.isIOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onRemoteMessageOpened);

    _initialized = true;

    // Do not block token registration on cold-start deep link lookup.
    unawaited(_loadInitialMessageWhenReady());
  }

  Future<void> _loadInitialMessageWhenReady() async {
    try {
      final initial = await FirebaseMessaging.instance
          .getInitialMessage()
          .timeout(_startupTimeout, onTimeout: () => null);
      if (initial != null) {
        _handleNotificationOpenData(initial.data);
      }
    } on TimeoutException {
      debugPrint('getInitialMessage timed out');
    } catch (e) {
      debugPrint('getInitialMessage failed: $e');
    }
  }

  Future<void> requestSystemPermission() async {
    if (kIsWeb) return;
    if (!await _ensureMessagingCore()) return;

    if (Platform.isAndroid) {
      await Permission.notification.request();
    }

    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } catch (e) {
      debugPrint('Push permission request failed: $e');
    }
  }

  Future<bool> hasSystemPermission() async {
    if (kIsWeb) return false;
    if (!await _ensureMessagingCore()) return false;

    if (Platform.isAndroid) {
      final androidStatus = await Permission.notification.status;
      if (androidStatus.isGranted || androidStatus.isLimited) {
        return true;
      }
    }

    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  Future<void> registerIfPermitted() async {
    if (kIsWeb) return;
    if (!await hasSystemPermission()) return;
    await registerDeviceToken();
  }

  /// Returns true when the FCM token was sent to the App API.
  Future<bool> registerDeviceToken({int attempts = 3}) async {
    final result = await registerDeviceTokenDetailed(attempts: attempts);
    return result == PushRegistrationResult.success;
  }

  Future<PushRegistrationResult> registerDeviceTokenDetailed({
    int attempts = 3,
  }) async {
    if (kIsWeb) return PushRegistrationResult.unavailable;
    if (!await _ensureMessagingCore()) {
      return PushRegistrationResult.unavailable;
    }

    final messaging = FirebaseMessaging.instance;
    final platform = Platform.isIOS ? 'ios' : 'android';

    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        if (Platform.isIOS) {
          await _waitForApnsToken(
            messaging,
            maxAttempts: attempt == 0 ? 40 : 20,
          );
        }

        final token = await messaging.getToken().timeout(
          Duration(seconds: Platform.isIOS ? 25 : 15),
          onTimeout: () => null,
        );
        if (token == null || token.length < 20) {
          if (attempt < attempts - 1) {
            await Future<void>.delayed(Duration(seconds: Platform.isIOS ? 3 : 2));
          }
          continue;
        }

        await _api.registerPushDevice(fcmToken: token, platform: platform);

        if (!_tokenRefreshListening) {
          _tokenRefreshListening = true;
          messaging.onTokenRefresh.listen((next) async {
            if (next.length < 20) return;
            try {
              await _api.registerPushDevice(fcmToken: next, platform: platform);
            } catch (_) {}
          });
        }
        return PushRegistrationResult.success;
      } catch (e) {
        debugPrint('Push registration attempt ${attempt + 1} failed: $e');
        if (attempt < attempts - 1) {
          await Future<void>.delayed(Duration(seconds: Platform.isIOS ? 3 : 2));
        } else {
          return PushRegistrationResult.apiFailed;
        }
      }
    }
    return PushRegistrationResult.tokenUnavailable;
  }

  Future<bool> registerIfSignedIn() async {
    return registerDeviceToken();
  }

  Future<void> _waitForApnsToken(
    FirebaseMessaging messaging, {
    int maxAttempts = 5,
  }) async {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final apns = await messaging.getAPNSToken();
      if (apns != null && apns.isNotEmpty) return;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // iOS shows the banner via setForegroundNotificationPresentationOptions.
    if (Platform.isIOS) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          kPushAndroidChannelId,
          kPushAndroidChannelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data['notification_id'],
    );
  }

  void _onRemoteMessageOpened(RemoteMessage message) {
    _handleNotificationOpenData(message.data);
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    _scheduleOpenNotificationsInbox();
  }

  void _handleNotificationOpenData(Map<String, dynamic> data) {
    if (isWhatsNewDetailPayload(data)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        openWhatsNewDetailFromData(data);
      });
      return;
    }
    _scheduleOpenNotificationsInbox();
  }

  void _scheduleOpenNotificationsInbox() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      openNotificationsInbox();
    });
  }
}

/// Opens the in-app notifications screen (from push tap or local notification).
void openNotificationsInbox() {
  final context = rootNavigatorKey.currentContext;
  if (context == null) return;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const NotificationsScreen(),
    ),
  );
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref.watch(radioudaanApiProvider));
});
