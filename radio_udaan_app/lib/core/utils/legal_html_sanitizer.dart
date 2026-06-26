/// Prepare WordPress / Elementor HTML for in-app [HtmlWidget] rendering.
String sanitizeLegalPageHtml(String raw) {
  var html = raw.trim();
  if (html.isEmpty) return '';

  html = html.replaceAll(
    RegExp(r'<style[^>]*>[\s\S]*?<\/style>', caseSensitive: false),
    '',
  );
  html = html.replaceAll(
    RegExp(r'<script[^>]*>[\s\S]*?<\/script>', caseSensitive: false),
    '',
  );
  html = html.replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');

  // Elementor sometimes leaves bare CSS text nodes; drop lines that look like rules.
  html = html.replaceAll(
    RegExp(r'\.ru-[a-z0-9_-]+\s*\{[^}]*\}', caseSensitive: false),
    '',
  );

  return html.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
}
