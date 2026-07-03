import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/providers/app_settings_provider.dart';
import '../../core/push/push_notification_service.dart';
import '../../core/theme/accessibility_scope.dart';
import '../../core/utils/keyboard_dismiss.dart';
import '../more/notifications_providers.dart';
import '../about/about_tab.dart';
import '../events/events_tab.dart';
import '../library/library_tab.dart';
import '../more/more_tab.dart';
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
    }
  }

  void _refreshPushRegistration() {
    final token = ref.read(authTokenProvider);
    if (token == null || token.isEmpty) return;
    unawaited(
      ref.read(pushNotificationServiceProvider).startupAfterBootstrap(
            loggedIn: true,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = ref.watch(appCopyProvider);
    ref.watch(appSettingsProvider);
    final index = ref.watch(mainShellTabIndexProvider);
    final unreadAsync = ref.watch(notificationUnreadCountProvider);
    final unreadCount = unreadAsync.value ?? 0;
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
                icon: _TabIcon(
                  icon: tabs[i].icon,
                  badgeCount: i == MainShellScreen.moreTabIndex ? unreadCount : 0,
                ),
                selectedIcon: _TabIcon(
                  icon: tabs[i].selected,
                  badgeCount: i == MainShellScreen.moreTabIndex ? unreadCount : 0,
                ),
                label: i == MainShellScreen.moreTabIndex && unreadCount > 0
                    ? '${tabs[i].label} (${unreadCount > 9 ? '9+' : unreadCount})'
                    : tabs[i].label,
                tooltip: '',
              ),
          ],
        ),
    );
  }
}

class _TabIcon extends StatelessWidget {
  const _TabIcon({required this.icon, required this.badgeCount});

  final IconData icon;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    if (badgeCount <= 0) return Icon(icon);
    final palette = context.udaan;
    final label = badgeCount > 9 ? '9+' : '$badgeCount';
    return ExcludeSemantics(
      child: Badge(
        label: Text(label),
        backgroundColor: palette.primary,
        textColor: palette.onPrimary,
        child: Icon(icon),
      ),
    );
  }
}
