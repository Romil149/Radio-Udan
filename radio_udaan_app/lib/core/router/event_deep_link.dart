import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../accessibility/udaan_semantics.dart';
import '../network/dio_exception_mapper.dart';
import '../providers/app_providers.dart';
import '../../features/events/event_registration_screen.dart';

/// Parses `/event/:eventId` paths from [GoRouter] locations.
int? parseEventDeepLinkPath(String path) {
  final match = RegExp(r'^/event/(\d+)$').firstMatch(path);
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}

/// Maps external campaign URLs to the in-app `/event/:id` route.
String? normalizeEventDeepLinkUri(Uri uri) {
  final wpMatch =
      RegExp(r'^/radioudaan/event/(\d+)/?$').firstMatch(uri.path);
  if (wpMatch != null) {
    return '/event/${wpMatch.group(1)}';
  }

  if (uri.scheme == 'radioudaan') {
    if (uri.host == 'event') {
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      if (RegExp(r'^\d+$').hasMatch(id)) {
        return '/event/$id';
      }
    }
    final customMatch = RegExp(r'^/event/(\d+)/?$').firstMatch(uri.path);
    if (customMatch != null) {
      return '/event/${customMatch.group(1)}';
    }
  }

  return null;
}

/// After sign-in completes, resume a pending event deep link when present.
void navigateAfterAuth(BuildContext context, WidgetRef ref) {
  final pending = ref.read(pendingEventDeepLinkProvider);
  if (pending != null) {
    context.go('/event/$pending');
    return;
  }
  context.go('/');
}

/// Opens event registration from a deep link once the user is fully signed in.
Future<void> openEventFromDeepLink(
  BuildContext context,
  WidgetRef ref,
  int eventId,
) async {
  ref.read(pendingEventDeepLinkProvider.notifier).state = null;
  ref.read(mainShellTabIndexProvider.notifier).state = 2;

  var title = ref.read(appCopyProvider).eventRegistrationTitle;
  try {
    final schema =
        await ref.read(radioudaanApiProvider).getEventForm(eventId);
    title = schema.event.title;
  } catch (e) {
    if (!context.mounted) return;
    final message = parseApiError(e).message;
    announce(context, message);
    context.go('/');
    return;
  }

  if (!context.mounted) return;
  final copy = ref.read(appCopyProvider);
  announce(context, copy.eventDeepLinkOpening(title));

  context.go('/');
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EventRegistrationScreen(
          eventId: eventId,
          title: title,
        ),
      ),
    );
  });
}
