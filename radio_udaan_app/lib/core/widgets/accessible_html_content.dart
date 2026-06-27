import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../theme/accessibility_scope.dart';
import '../theme/udaan_google_fonts.dart';

typedef AccessibleHtmlStylesBuilder = Map<String, String>? Function(
  BuildContext context,
  dynamic element,
);

/// WP HTML body tuned for screen readers (no duplicate container labels).
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
      onTapUrl: onTapUrl,
    );
  }
}
