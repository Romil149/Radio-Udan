import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/accessibility_scope.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/utils/legal_html_sanitizer.dart';
import '../../core/utils/wp_media_url.dart';
import '../../core/widgets/accessible_html_content.dart';
import '../../core/widgets/brand_app_bar.dart';

/// Native scroll view for WP page body HTML (`GET /config` → `legal_pages`).
class LegalContentScreen extends StatelessWidget {
  const LegalContentScreen({
    required this.title,
    required this.html,
    required this.apiBaseUrl,
    this.siteUrl,
    super.key,
  });

  final String title;
  final String html;
  final String apiBaseUrl;
  final String? siteUrl;

  Future<bool> _openExternalLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Map<String, String>? _stylesForElement(BuildContext context, dynamic element) {
    final palette = context.udaan;
    final tag = element.localName?.toLowerCase();
    final classes = element.classes.map((c) => c.toString().toLowerCase()).toSet();

    if (classes.contains('ru-about-tag') ||
        classes.contains('ru-highlight-label')) {
      return {
        'color': _hex(palette.primaryGlow),
        'font-size': '14px',
        'font-weight': '700',
        'margin-bottom': '8px',
      };
    }
    if (classes.contains('ru-about-title') ||
        classes.contains('ru-highlight-number')) {
      return {
        'color': _hex(palette.onBackground),
        'font-size': '26px',
        'font-weight': '800',
        'line-height': '1.25',
        'margin-bottom': '12px',
      };
    }
    if (classes.contains('ru-about-text') ||
        classes.contains('ru-highlight-text')) {
      return {
        'color': _hex(palette.onSurfaceVariant),
        'font-size': '16px',
        'line-height': '1.5',
        'margin-bottom': '12px',
      };
    }
    if (classes.contains('ru-highlight-box') || classes.contains('ru-about-note')) {
      return {
        'color': _hex(palette.onBackground),
        'background-color': _hex(palette.surfaceContainer),
        'border': '1px solid ${_hex(palette.outlineVariant)}',
        'border-radius': '12px',
        'padding': '16px',
        'margin': '16px 0',
      };
    }

    switch (tag) {
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
        return {
          'color': _hex(palette.onBackground),
          'font-weight': '800',
          'margin-top': '1.2em',
          'margin-bottom': '0.5em',
        };
      case 'a':
        return {
          'color': _hex(palette.primaryGlow),
          'text-decoration': 'underline',
        };
      case 'p':
      case 'li':
        return {
          'color': _hex(palette.onSurfaceVariant),
          'margin-bottom': '0.75em',
          'line-height': '1.5',
        };
      default:
        return null;
    }
  }

  String _hex(Color color) =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

  @override
  Widget build(BuildContext context) {
    final bodyHtml = sanitizeLegalPageHtml(
      rewriteWpHtmlMediaUrls(
        html,
        apiBaseUrl: apiBaseUrl,
        siteUrl: siteUrl,
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: BrandAppBar(title: title),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(BrandTokens.screenPadding),
          children: [
            AccessibleHtmlContent(
              html: bodyHtml,
              customStylesBuilder: _stylesForElement,
              onTapUrl: _openExternalLink,
            ),
          ],
        ),
      ),
    );
  }
}
