/// Parses `radioudaan://donate/verify?order_id=...` return URLs.
///
/// Also accepts Razorpay Payment Link callback query keys when present.
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
  final orderId = _orderIdFromQuery(uri.queryParameters);
  if (orderId == null) {
    return null;
  }
  return '/donate/verify?order_id=${Uri.encodeComponent(orderId)}';
}

String? parseDonateVerifyOrderId(String path, Map<String, String> query) {
  if (path != '/donate/verify') {
    return null;
  }
  return _orderIdFromQuery(query);
}

String? _orderIdFromQuery(Map<String, String> query) {
  for (final key in ['order_id', 'razorpay_order_id']) {
    final value = query[key]?.trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return null;
}
