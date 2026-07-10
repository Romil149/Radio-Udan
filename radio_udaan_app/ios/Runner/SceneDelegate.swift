import Flutter
import UIKit
import FirebaseMessaging

class SceneDelegate: FlutterSceneDelegate {
  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    // UIScene: applicationDidBecomeActive often does not run — re-register here.
    UIApplication.shared.registerForRemoteNotifications()
    if let token = AppDelegate.cachedApnsToken {
      Messaging.messaging().apnsToken = token
    }
  }
}
