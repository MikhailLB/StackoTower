import Flutter
import UIKit
import UserNotifications

class SceneDelegate: FlutterSceneDelegate {
  static let tapUrlKey = "flutter.a_tu"

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    if let response = connectionOptions.notificationResponse,
       let url = SceneDelegate.extractUrl(
         from: response.notification.request.content.userInfo
       )
    {
      SceneDelegate.persist(url: url)
    }
  }

  override func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    super.scene(scene, continue: userActivity)
  }

  static func extractUrl(from userInfo: [AnyHashable: Any]) -> String? {
    let keys = ["url", "link", "target", "deeplink", "deep_link"]

    func scan(_ map: [AnyHashable: Any]) -> String? {
      for key in keys {
        if let raw = map[key] as? String,
           !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          return raw.trimmingCharacters(in: .whitespacesAndNewlines)
        }
      }
      return nil
    }

    if let direct = scan(userInfo) { return direct }

    if let nested = userInfo["data"] as? [AnyHashable: Any],
       let url = scan(nested) { return url }

    if let nested = userInfo["payload"] as? [AnyHashable: Any],
       let url = scan(nested) { return url }

    return nil
  }

  static func persist(url: String) {
    let d = UserDefaults.standard
    d.set(url, forKey: tapUrlKey)
    d.synchronize()
  }
}
