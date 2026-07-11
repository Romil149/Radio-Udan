import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/providers/app_settings_provider.dart';
import '../../core/push/push_notification_service.dart';
import '../../core/theme/accessibility_scope.dart';
import '../../core/utils/keyboard_dismiss.dart';
import '../about/about_tab.dart';
import '../events/events_tab.dart';
import '../library/library_tab.dart';
import '../more/more_tab.dart';
import '../radio/radio_audio_service.dart';
import '../radio/radio_stream_metadata.dart';
import '../radio/radio_tab.dart';

/// Primary navigation: five top-level product areas.
class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  static const int aboutTabIndex = 3;
  static const int moreTabIndex = 4;

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshPushRegistration());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPushRegistration();
      return;
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _suspendInactiveRadio();
    }
  }

  void _suspendInactiveRadio() {
    if (ref.read(radioAudiblePlaybackProvider)) return;
    unawaited(suspendInactiveRadioPlayback());
  }

  void _refreshPushRegistration() {
    final token = ref.read(authTokenProvider);
    if (token == null || token.isEmpty) return;
    unawaited(
      ref.read(pushNotificationServiceProvider).syncForLoggedInUser(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = ref.watch(appCopyProvider);
    ref.watch(appSettingsProvider);
    final index = ref.watch(mainShellTabIndexProvider);
    final tabs = [
      (label: copy.tabRadio, icon: Icons.radio, selected: Icons.radio),
      (
        label: copy.tabLibrary,
        icon: Icons.video_library_outlined,
        selected: Icons.video_library,
      ),
      (label: copy.tabEvents, icon: Icons.event_outlined, selected: Icons.event),
      (
        label: copy.tabAbout,
        icon: Icons.info_outline,
        selected: Icons.info,
      ),
      (label: copy.tabMore, icon: Icons.menu, selected: Icons.menu),
    ];

    final palette = context.udaan;

    final tabBodies = [
      RepaintBoundary(child: RadioTab()),
      RepaintBoundary(child: LibraryTab()),
      RepaintBoundary(child: EventsTab()),
      RepaintBoundary(child: AboutTab()),
      RepaintBoundary(child: MoreTab()),
    ];

    return Scaffold(
      backgroundColor: palette.background,
      body: IndexedStack(
        index: index,
        children: [
          for (var i = 0; i < tabs.length; i++) tabBodies[i],
        ],
      ),
      bottomNavigationBar: NavigationBar(
          backgroundColor: palette.surfaceContainerHigh,
          indicatorColor: palette.primary.withValues(alpha: 0.25),
          surfaceTintColor: Colors.transparent,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          selectedIndex: index,
          onDestinationSelected: (i) {
            dismissKeyboard(context);
            ref.read(mainShellTabIndexProvider.notifier).state = i;
          },
          destinations: [
            for (var i = 0; i < tabs.length; i++)
              NavigationDestination(
                icon: Icon(tabs[i].icon),
                selectedIcon: Icon(tabs[i].selected),
                label: tabs[i].label,
                tooltip: '',
              ),
          ],
        ),
    );
  }
}
