import Flutter
import UIKit

/// Full-screen host that presents `UIActivityViewController`.
///
/// Setting `sheet.detents = [.large()]` on `UIActivityViewController` alone is
/// ignored on current iOS — the system share sheet stays medium/half. Presenting
/// from a full-screen host with `.fullScreen` on the activity forces full height.
final class ShareHostViewController: UIViewController {
  private let shareText: String
  private let onFinished: (String) -> Void
  private var didPresentActivity = false

  init(text: String, onFinished: @escaping (String) -> Void) {
    self.shareText = text
    self.onFinished = onFinished
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .fullScreen
    modalTransitionStyle = .coverVertical
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    guard !didPresentActivity else { return }
    didPresentActivity = true
    presentShareSheet()
  }

  private func presentShareSheet() {
    let activity = UIActivityViewController(
      activityItems: [shareText],
      applicationActivities: nil
    )

    // Force full coverage — pageSheet/medium is what caused the half sheet.
    activity.modalPresentationStyle = .fullScreen

    if #available(iOS 15.0, *), let sheet = activity.sheetPresentationController {
      sheet.detents = [.large()]
      sheet.selectedDetentIdentifier = .large
      sheet.prefersGrabberVisible = false
      if #available(iOS 16.0, *) {
        sheet.prefersPageSizing = false
      }
    }

    if let popover = activity.popoverPresentationController {
      popover.sourceView = view
      popover.sourceRect = CGRect(
        x: view.bounds.midX,
        y: view.bounds.midY,
        width: 1,
        height: 1
      )
      popover.permittedArrowDirections = []
    }

    activity.completionWithItemsHandler = { [weak self] _, completed, _, error in
      let status: String
      if error != nil {
        status = "unavailable"
      } else if completed {
        status = "success"
      } else {
        status = "dismissed"
      }
      DispatchQueue.main.async {
        self?.onFinished(status)
        self?.dismiss(animated: true)
      }
    }

    present(activity, animated: true) { [weak activity] in
      guard #available(iOS 15.0, *), let activity else { return }
      if let sheet = activity.sheetPresentationController {
        sheet.animateChanges {
          sheet.detents = [.large()]
          sheet.selectedDetentIdentifier = .large
        }
      }
    }
  }
}

/// Presents the system share UI full screen on iPhone.
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

      var settled = false
      let finish: (String) -> Void = { status in
        guard !settled else { return }
        settled = true
        result(["status": status])
      }

      let host = ShareHostViewController(text: text, onFinished: finish)
      presenter.present(host, animated: true)
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
