import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/brand_tokens.dart';
import '../../core/theme/udaan_colors.dart';
import '../../core/utils/wp_media_url.dart';
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

  @override
  Widget build(BuildContext context) {
    final bodyHtml = rewriteWpHtmlMediaUrls(
      html,
      apiBaseUrl: apiBaseUrl,
      siteUrl: siteUrl,
    );

    return Scaffold(
      backgroundColor: UdaanColors.background,
      appBar: BrandAppBar(title: title),
      body: SafeArea(
        child: Semantics(
          container: true,
          label: title,
          child: ListView(
            padding: const EdgeInsets.all(BrandTokens.screenPadding),
            children: [
              HtmlWidget(
                bodyHtml,
                textStyle: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  color: UdaanColors.onSurfaceVariant,
                ),
                customStylesBuilder: (element) {
                  switch (element.localName) {
                    case 'h1':
                    case 'h2':
                    case 'h3':
                    case 'h4':
                      return {
                        'color': '#E8EAED',
                        'font-weight': '800',
                        'margin-top': '1.2em',
                        'margin-bottom': '0.5em',
                      };
                    case 'a':
                      return {
                        'color': '#7DD3FC',
                        'text-decoration': 'underline',
                      };
                    case 'p':
                    case 'li':
                      return {
                        'color': '#C5C9D0',
                        'margin-bottom': '0.75em',
                      };
                    default:
                      return null;
                  }
                },
                onTapUrl: (url) => _openExternalLink(url),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
