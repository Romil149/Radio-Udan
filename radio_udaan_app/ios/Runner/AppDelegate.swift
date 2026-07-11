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
    Self.registerShareChannel(messenger: engineBridge.applicationRegistrar.messenger())
    Self.applyCachedApnsTokenIfReady()
  }

  /// iOS system share with large sheet detent (full sheet + Close X).
  private static func registerShareChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "radioudaan/share",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "shareText" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let args = call.arguments as? [String: Any],
        let text = args["text"] as? String,
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      else {
        result(
          FlutterError(
            code: "BAD_ARGS",
            message: "shareText requires non-empty text",
            details: nil
          )
        )
        return
      }
      ShareLargeSheet.present(text: text, result: result)
    }
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
