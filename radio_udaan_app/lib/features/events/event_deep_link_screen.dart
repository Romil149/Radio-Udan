import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/event_deep_link.dart';
import '../../core/theme/udaan_colors.dart';
import '../../core/providers/app_providers.dart';

/// Handles `/event/:eventId` — switches to Events tab and opens registration.
class EventDeepLinkScreen extends ConsumerStatefulWidget {
  const EventDeepLinkScreen({required this.eventId, super.key});

  final int eventId;

  @override
  ConsumerState<EventDeepLinkScreen> createState() =>
      _EventDeepLinkScreenState();
}

class _EventDeepLinkScreenState extends ConsumerState<EventDeepLinkScreen> {
  AppCopy get _copy => ref.read(appCopyProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      openEventFromDeepLink(context, ref, widget.eventId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Semantics(
          label: _copy.eventDeepLinkLoading,
          liveRegion: true,
          child: CircularProgressIndicator(color: context.udaan.primary),
        ),
      ),
    );
  }
}
