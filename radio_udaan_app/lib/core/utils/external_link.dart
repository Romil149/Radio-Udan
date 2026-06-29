import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../accessibility/udaan_semantics.dart';
import '../config/app_branding.dart';
import '../config/app_copy_accessors.dart';

/// Opens [url] in the system browser; shows copy-driven errors on failure.
Future<void> openExternalUrl(
  BuildContext context,
  String url, {
  AppCopy? copy,
}) async {
  final strings = copy ?? AppCopy.fallback;
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !uri.hasScheme) {
    if (!context.mounted) return;
    announceAndSnack(context, strings.linkUnavailable);
    return;
  }

  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      announceAndSnack(context, strings.linkOpenFailed);
    }
  } catch (_) {
    if (context.mounted) {
      announceAndSnack(context, strings.linkOpenFailed);
    }
  }
}
