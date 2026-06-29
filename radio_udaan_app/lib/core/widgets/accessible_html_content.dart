import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../accessibility/udaan_semantics.dart';
import '../theme/accessibility_scope.dart';
import '../theme/udaan_google_fonts.dart';

typedef AccessibleHtmlStylesBuilder = Map<String, String>? Function(
  BuildContext context,
  dynamic element,
);

/// WP HTML body tuned for screen readers (headings as landmarks).
class AccessibleHtmlContent extends StatelessWidget {
  const AccessibleHtmlContent({
    required this.html,
    this.textStyle,
    this.customStylesBuilder,
    this.onTapUrl,
    super.key,
  });

  final String html;
  final TextStyle? textStyle;
  final AccessibleHtmlStylesBuilder? customStylesBuilder;
  final Future<bool> Function(String url)? onTapUrl;

  Widget? _headingBuilder(BuildContext context, dynamic element) {
    final tag = element.localName?.toLowerCase() ?? '';
    if (!const {'h1', 'h2', 'h3', 'h4'}.contains(tag)) {
      return null;
    }
    final text = element.text?.trim() ?? '';
    if (text.isEmpty) return null;
    final palette = context.udaan;
    final fontSize = switch (tag) {
      'h1' => 26.0,
      'h2' => 22.0,
      'h3' => 20.0,
      _ => 18.0,
    };
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: UdaanScreenHeader(
        title: text,
        style: udaanGoogleFont(
          context,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: palette.onBackground,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;
    return HtmlWidget(
      html,
      textStyle: textStyle ??
          udaanGoogleFont(
            context,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.5,
            color: palette.onSurfaceVariant,
          ),
      customStylesBuilder: customStylesBuilder == null
          ? null
          : (element) => customStylesBuilder!(context, element),
      customWidgetBuilder: (element) => _headingBuilder(context, element),
      onTapUrl: onTapUrl,
    );
  }
}
