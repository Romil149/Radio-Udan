/// Parses `radioudaan://donate/verify?order_id=...` return URLs.
String? normalizeDonateDeepLinkUri(Uri uri) {
  if (uri.scheme != 'radioudaan') {
    return null;
  }
  if (uri.host != 'donate') {
    return null;
  }
  final segments = uri.pathSegments;
  if (segments.isEmpty || segments.first != 'verify') {
    return null;
  }
  final orderId = uri.queryParameters['order_id']?.trim() ?? '';
  if (orderId.isEmpty) {
    return null;
  }
  return '/donate/verify?order_id=${Uri.encodeComponent(orderId)}';
}

String? parseDonateVerifyOrderId(String path, Map<String, String> query) {
  if (path != '/donate/verify') {
    return null;
  }
  final orderId = query['order_id']?.trim() ?? '';
  return orderId.isNotEmpty ? orderId : null;
}
