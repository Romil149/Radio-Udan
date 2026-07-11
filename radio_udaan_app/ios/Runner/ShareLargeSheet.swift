import Flutter
import UIKit

/// Presents `UIActivityViewController` with a large sheet detent so iOS shows
/// the full share UI (Close X) instead of the default medium half-sheet.
enum ShareLargeSheet {
  static func present(
    text: String,
    result: @escaping FlutterResult
  ) {
    DispatchQueue.main.async {
      guard let presenter = topViewController() else {
        result(
          FlutterError(
            code: "NO_PRESENTER",
            message: "No view controller available to present share sheet",
            details: nil
          )
        )
        return
      }

      let activity = UIActivityViewController(
        activityItems: [text],
        applicationActivities: nil
      )

      // Prefer full / large sheet (iOS 15+). Only large so the sheet opens expanded.
      if #available(iOS 15.0, *) {
        if let sheet = activity.sheetPresentationController {
          sheet.detents = [.large()]
          sheet.selectedDetentIdentifier = .large
          sheet.prefersGrabberVisible = true
        }
      }

      if let popover = activity.popoverPresentationController {
        popover.sourceView = presenter.view
        popover.sourceRect = CGRect(
          x: presenter.view.bounds.midX,
          y: presenter.view.bounds.midY,
          width: 1,
          height: 1
        )
        popover.permittedArrowDirections = []
      }

      var settled = false
      let finish: (String) -> Void = { status in
        guard !settled else { return }
        settled = true
        result(["status": status])
      }

      activity.completionWithItemsHandler = { _, completed, _, error in
        if error != nil {
          finish("unavailable")
        } else if completed {
          finish("success")
        } else {
          finish("dismissed")
        }
      }

      presenter.present(activity, animated: true) {
        // Some iOS versions attach sheetPresentationController only after present.
        if #available(iOS 15.0, *) {
          if let sheet = activity.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.selectedDetentIdentifier = .large
            sheet.prefersGrabberVisible = true
          }
        }
      }
    }
  }

  private static func topViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let window =
      scenes.flatMap(\.windows).first(where: \.isKeyWindow)
      ?? scenes.first?.windows.first
    var controller = window?.rootViewController
    while let presented = controller?.presentedViewController {
      controller = presented
    }
    return controller
  }
}
