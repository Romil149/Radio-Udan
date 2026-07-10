import Flutter
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

/// Classic AppDelegate (no UIScene / FlutterImplicitEngineDelegate).
/// UIScene broke FlutterFire APNs token delivery — getAPNSToken stayed nil.
@main
@objc class AppDelegate: FlutterAppDelegate {
  private static var cachedApnsToken: Data?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Native configure so Messaging can accept the APNs token before Dart runs.
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

    GeneratedPluginRegistrant.register(with: self)

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    application.registerForRemoteNotifications()
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
