import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Outcome of a system share sheet presentation.
enum SystemShareStatus {
  success,
  dismissed,
  unavailable,
}

/// Shares [text] via the OS sheet.
///
/// On iOS uses a MethodChannel that presents `UIActivityViewController` with
/// large detent (full sheet). Android / other platforms use `share_plus`.
Future<SystemShareStatus> shareSystemText(String text) async {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return SystemShareStatus.unavailable;

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    try {
      final raw = await const MethodChannel('radioudaan/share')
          .invokeMethod<dynamic>('shareText', <String, dynamic>{
        'text': trimmed,
      });
      final status = raw is Map ? raw['status'] as String? : null;
      switch (status) {
        case 'success':
          return SystemShareStatus.success;
        case 'dismissed':
          return SystemShareStatus.dismissed;
        default:
          return SystemShareStatus.unavailable;
      }
    } on MissingPluginException {
      // Fall through to share_plus if native channel is absent (tests / old builds).
    } on PlatformException {
      return SystemShareStatus.unavailable;
    }
  }

  final result =
      await SharePlus.instance.share(ShareParams(text: trimmed));
  switch (result.status) {
    case ShareResultStatus.success:
      return SystemShareStatus.success;
    case ShareResultStatus.dismissed:
      return SystemShareStatus.dismissed;
    case ShareResultStatus.unavailable:
      return SystemShareStatus.unavailable;
  }
}
