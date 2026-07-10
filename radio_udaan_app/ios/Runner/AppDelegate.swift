import Flutter
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

/// UIScene + FlutterImplicitEngineDelegate is required for Flutter 3.38+ launch.
/// Removing the scene manifest (build 47) crashed at startup on device.
@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Cached so SceneDelegate / Dart can re-apply after Firebase Messaging is ready.
  static var cachedApnsToken: Data?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Native configure so Messaging can accept APNs before Dart Firebase.initializeApp.
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let token = Self.cachedApnsToken {
      Messaging.messaging().apnsToken = token
    }
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Self.cachedApnsToken = deviceToken
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("APNs registration failed: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}
