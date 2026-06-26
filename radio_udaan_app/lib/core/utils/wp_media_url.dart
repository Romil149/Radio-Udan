/// Rewrites WordPress media URLs to match the app’s reachable API/site origin.
///
/// WP often returns `https://radio/wp-content/...` while the app may use
/// `http://192.168.x.x` or another host override — images would 404 otherwise.
String siteOriginFromApiBase(String apiBaseUrl) {
  final trimmed = apiBaseUrl.trim();
  if (trimmed.isEmpty) return '';

  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.host.isEmpty) return '';

  final port = uri.hasPort &&
          uri.port != 80 &&
          uri.port != 443 &&
          !(uri.scheme == 'http' && uri.port == 80) &&
          !(uri.scheme == 'https' && uri.port == 443)
      ? uri.port
      : null;

  return Uri(
    scheme: uri.scheme.isEmpty ? 'https' : uri.scheme,
    host: uri.host,
    port: port,
  ).toString();
}

String resolveWpMediaUrl(
  String rawUrl, {
  required String apiBaseUrl,
  String? siteUrl,
}) {
  final raw = rawUrl.trim();
  if (raw.isEmpty) return '';

  var origin = siteOriginFromApiBase(apiBaseUrl);
  if (origin.isEmpty && siteUrl != null && siteUrl.trim().isNotEmpty) {
    origin = siteOriginFromApiBase(siteUrl);
  }
  if (origin.isEmpty) return raw;

  if (raw.startsWith('//')) {
    final originUri = Uri.parse(origin);
    return '${originUri.scheme}:$raw';
  }

  if (raw.startsWith('/')) {
    return '$origin$raw';
  }

  final parsed = Uri.tryParse(raw);
  if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) {
    return raw;
  }

  final originUri = Uri.parse(origin);
  final sameHost = parsed.host == originUri.host &&
      parsed.scheme == originUri.scheme &&
      parsed.port == originUri.port;
  if (sameHost) return raw;

  // Only rewrite WordPress media URLs (e.g. https://radio/wp-content/...).
  // External CDNs such as YouTube (i.ytimg.com) must stay untouched.
  if (!_looksLikeWpMedia(parsed)) return raw;

  return parsed
      .replace(
        scheme: originUri.scheme,
        host: originUri.host,
        port: originUri.hasPort ? originUri.port : null,
      )
      .toString();
}

bool _looksLikeWpMedia(Uri uri) {
  if (uri.path.contains('/wp-content/')) return true;
  // Local WP hostname used in this project's dev environment.
  if (uri.host == 'radio') return true;
  return false;
}

/// Rewrites `src` / `href` attributes in HTML from WP hosts to the app API origin.
String rewriteWpHtmlMediaUrls(
  String html, {
  required String apiBaseUrl,
  String? siteUrl,
}) {
  if (html.trim().isEmpty) return html;

  return html.replaceAllMapped(
    RegExp(r'''((?:src|href)=["'])([^"']+)(["'])''', caseSensitive: false),
    (match) {
      final prefix = match.group(1) ?? '';
      final rawUrl = match.group(2) ?? '';
      final suffix = match.group(3) ?? '';
      final resolved = resolveWpMediaUrl(
        rawUrl,
        apiBaseUrl: apiBaseUrl,
        siteUrl: siteUrl,
      );
      return '$prefix$resolved$suffix';
    },
  );
}
