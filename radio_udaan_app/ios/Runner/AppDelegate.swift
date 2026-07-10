import Flutter
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

/// Matches the last known-good launch path (build 46): UIScene + ImplicitEngine,
/// Dart owns Firebase.initializeApp. Do not call FirebaseApp.configure() here —
/// early native configure contributed to post-46 TestFlight crashes.
@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  static var cachedApnsToken: Data?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    Self.applyCachedApnsTokenIfReady()
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Self.cachedApnsToken = deviceToken
    Self.applyCachedApnsTokenIfReady()
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("APNs registration failed: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  /// Only touch Messaging after Firebase is configured (by Dart).
  static func applyCachedApnsTokenIfReady() {
    guard FirebaseApp.app() != nil, let token = cachedApnsToken else { return }
    Messaging.messaging().apnsToken = token
  }
}
