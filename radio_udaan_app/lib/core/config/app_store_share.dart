import 'package:flutter/foundation.dart';

/// Platform-specific store listing URL from `GET /config`.
String? storeListingUrl({
  required String? appStoreUrl,
  required String? playStoreUrl,
}) {
  final ios = appStoreUrl?.trim() ?? '';
  final android = playStoreUrl?.trim() ?? '';

  if (kIsWeb) {
    if (android.isNotEmpty) return android;
    if (ios.isNotEmpty) return ios;
    return null;
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      return ios.isNotEmpty ? ios : null;
    case TargetPlatform.android:
      return android.isNotEmpty ? android : null;
    default:
      if (android.isNotEmpty) return android;
      if (ios.isNotEmpty) return ios;
      return null;
  }
}

/// Share sheet text: WordPress message + platform store link.
String buildAppShareMessage({
  required String message,
  required String? appStoreUrl,
  required String? playStoreUrl,
}) {
  final storeUrl = storeListingUrl(
    appStoreUrl: appStoreUrl,
    playStoreUrl: playStoreUrl,
  );
  return [
    message.trim(),
    storeUrl?.trim() ?? '',
  ].where((part) => part.isNotEmpty).join('\n\n');
}
