import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_providers.dart';
import '../utils/external_link.dart';
import 'app_router.dart';
import 'whats_new_deep_link.dart';

/// Whether [data] includes an in-app or external Open destination.
bool hasNotificationDestination(Map<String, dynamic> data) {
  final route = data['route']?.toString() ?? '';
  switch (route) {
    case 'radio':
    case 'events':
    case 'whats_new_detail':
      return true;
    case 'url':
      final url = data['url']?.toString().trim() ?? '';
      return url.startsWith('https://');
    default:
      return false;
  }
}

/// Spoken / visible label for the detail Open button.
String notificationDestinationButtonLabel(
  AppCopy copy,
  Map<String, dynamic> data,
) {
  switch (data['route']?.toString()) {
    case 'radio':
      return copy.notificationOpenRadio;
    case 'events':
      return copy.notificationOpenEvents;
    case 'whats_new_detail':
      return copy.notificationViewUpdate;
    case 'url':
      return copy.notificationOpenLink;
    default:
      return copy.notificationOpen;
  }
}

/// Navigates to the destination encoded in notification [data].
Future<void> openNotificationDestination(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> data,
) async {
  final route = data['route']?.toString() ?? '';
  final copy = ref.read(appCopyProvider);

  switch (route) {
    case 'radio':
      _popToMainShell(context);
      ref.read(mainShellTabIndexProvider.notifier).state = 0;
      return;
    case 'events':
      _popToMainShell(context);
      ref.read(mainShellTabIndexProvider.notifier).state = 2;
      return;
    case 'whats_new_detail':
      openWhatsNewDetailFromData(data);
      return;
    case 'url':
      final url = data['url']?.toString().trim() ?? '';
      if (!context.mounted) return;
      await openExternalUrl(context, url, copy: copy);
      return;
    default:
      return;
  }
}

void _popToMainShell(BuildContext context) {
  final nav = Navigator.of(context);
  if (nav.canPop()) {
    nav.popUntil((route) => route.isFirst);
  }
  final shellContext = rootNavigatorKey.currentContext;
  if (shellContext != null && shellContext.mounted) {
    shellContext.go('/');
  }
}
