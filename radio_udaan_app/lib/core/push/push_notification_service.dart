import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/more/notifications_screen.dart';
import '../../firebase_options.dart';
import '../api/radioudaan_api.dart';
import '../providers/app_providers.dart';
import '../router/app_router.dart';

/// Android notification channel — must match WP FCM `channel_id`.
const kPushAndroidChannelId = 'radioudaan_alerts';
const kPushAndroidChannelName = 'Radio Udaan Alerts';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Registers FCM token and shows foreground notifications.
class PushNotificationService {
  PushNotificationService(this._api);

  static const Duration _startupTimeout = Duration(seconds: 8);

  final RadioUdaanApi _api;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _tokenRefreshListening = false;

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

  /// Background sync after login, cold start, or app resume. No in-app button required.
  Future<void> syncForLoggedInUser() async {
    try {
      await initialize().timeout(_startupTimeout);
    } on TimeoutException {
      debugPrint('Push initialize timed out');
    } catch (e) {
      debugPrint('Push sync failed: $e');
      return;
    }

    if (!_initialized) return;

    var registered = await _ensureRegistered();
    if (!registered) {
      // iOS APNs/FCM can lag briefly after grant — one silent retry.
      await Future<void>.delayed(const Duration(seconds: 20));
      registered = await _ensureRegistered();
    }
    if (kDebugMode) {
      debugPrint(registered ? 'Push device registered' : 'Push device not registered');
    }
  }

  /// Runs after home/login is visible — never block cold start on FCM/APNs.
  Future<void> startupAfterBootstrap({required bool loggedIn}) async {
    if (!loggedIn) return;
    await syncForLoggedInUser();
  }

  Future<bool> _ensureRegistered() async {
    if (!_initialized) return false;

    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        await requestSystemPermission();
      }
    } catch (e) {
      debugPrint('Push permission check failed: $e');
    }

    if (!await hasSystemPermission()) return false;
    return registerDeviceToken(attempts: 5);
  }

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    if (!await ensureFirebase()) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

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

    try {
      final initial = await FirebaseMessaging.instance
          .getInitialMessage()
          .timeout(_startupTimeout, onTimeout: () => null);
      if (initial != null) {
        _scheduleOpenNotificationsInbox();
      }
    } on TimeoutException {
      debugPrint('getInitialMessage timed out');
    }
  }

  Future<void> requestSystemPermission() async {
    if (kIsWeb || !_initialized) return;
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
    if (kIsWeb || !_initialized) return false;
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  Future<void> registerIfPermitted() async {
    if (kIsWeb || !_initialized) return;
    if (!await hasSystemPermission()) return;
    await registerDeviceToken();
  }

  /// Returns true when the FCM token was sent to the App API.
  Future<bool> registerDeviceToken({int attempts = 3}) async {
    if (kIsWeb || !_initialized) return false;

    final messaging = FirebaseMessaging.instance;
    final platform = Platform.isIOS ? 'ios' : 'android';

    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        if (Platform.isIOS) {
          await _waitForApnsToken(
            messaging,
            maxAttempts: attempt == 0 ? 10 : 5,
          );
        }

        final token = await messaging.getToken().timeout(
          const Duration(seconds: 15),
          onTimeout: () => null,
        );
        if (token == null || token.length < 20) {
          if (attempt < attempts - 1) {
            await Future<void>.delayed(const Duration(seconds: 2));
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
        return true;
      } catch (e) {
        debugPrint('Push registration attempt ${attempt + 1} failed: $e');
        if (attempt < attempts - 1) {
          await Future<void>.delayed(const Duration(seconds: 2));
        }
      }
    }
    return false;
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
      await Future<void>.delayed(const Duration(milliseconds: 600));
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
    _scheduleOpenNotificationsInbox();
  }

  void _onLocalNotificationTap(NotificationResponse response) {
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
