/// In-app legal/about bodies from `GET /config` → `legal_pages`.
class LegalPageContent {
  const LegalPageContent({
    required this.pageId,
    required this.title,
    required this.html,
    this.pageUrl,
    this.updatedAt,
  });

  factory LegalPageContent.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return const LegalPageContent(pageId: 0, title: '', html: '');
    }
    return LegalPageContent(
      pageId: (json['page_id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      html: json['html']?.toString() ?? '',
      pageUrl: json['page_url']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  final int pageId;
  final String title;
  final String html;
  final String? pageUrl;
  final String? updatedAt;

  bool get hasHtml => html.trim().isNotEmpty;
}

class LegalPagesConfig {
  const LegalPagesConfig({this.privacy, this.terms, this.about});

  factory LegalPagesConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return const LegalPagesConfig();
    }
    LegalPageContent? parse(dynamic raw) {
      if (raw is! Map<String, dynamic>) return null;
      final page = LegalPageContent.fromJson(raw);
      return page.hasHtml ? page : null;
    }

    return LegalPagesConfig(
      privacy: parse(json['privacy']),
      terms: parse(json['terms']),
      about: parse(json['about']),
    );
  }

  final LegalPageContent? privacy;
  final LegalPageContent? terms;
  final LegalPageContent? about;
}
