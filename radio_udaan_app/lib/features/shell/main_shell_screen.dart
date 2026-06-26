import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/push/notification_permission_flow.dart';
import '../../core/theme/accessibility_scope.dart';
import '../more/notifications_providers.dart';
import '../events/events_tab.dart';
import '../library/library_tab.dart';
import '../more/more_tab.dart';
import '../radio/radio_tab.dart';

/// Primary navigation: four top-level product areas (Gate A scope).
class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  static const int moreTabIndex = 3;

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      NotificationPermissionFlow.maybeShow(context, ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final copy = ref.watch(appCopyProvider);
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
      (label: copy.tabMore, icon: Icons.menu, selected: Icons.menu),
    ];

    final palette = context.udaan;

    return Scaffold(
      backgroundColor: palette.background,
      body: IndexedStack(
        index: index,
        children: const [
          RepaintBoundary(child: RadioTab()),
          RepaintBoundary(child: LibraryTab()),
          RepaintBoundary(child: EventsTab()),
          RepaintBoundary(child: MoreTab()),
        ],
      ),
      bottomNavigationBar: Semantics(
        container: true,
        label: copy.mainNavigation,
        child: NavigationBar(
          backgroundColor: palette.surfaceContainerHigh,
          indicatorColor: palette.primary.withValues(alpha: 0.25),
          surfaceTintColor: Colors.transparent,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          selectedIndex: index,
          onDestinationSelected: (i) {
            ref.read(mainShellTabIndexProvider.notifier).state = i;
            SemanticsService.sendAnnouncement(
              View.of(context),
              '${tabs[i].label} tab selected',
              Directionality.of(context),
            );
          },
          destinations: [
            for (var i = 0; i < tabs.length; i++)
              NavigationDestination(
                icon: Semantics(
                  selected: index == i,
                  label: i == MainShellScreen.moreTabIndex && unreadCount > 0
                      ? '${tabs[i].label}. ${copy.unreadNotificationsBadge(unreadCount)}'
                      : tabs[i].label,
                  child: _TabIcon(
                    icon: tabs[i].icon,
                    badgeCount: i == MainShellScreen.moreTabIndex ? unreadCount : 0,
                  ),
                ),
                selectedIcon: Semantics(
                  selected: true,
                  label: i == MainShellScreen.moreTabIndex && unreadCount > 0
                      ? '${tabs[i].label}, selected. ${copy.unreadNotificationsBadge(unreadCount)}'
                      : '${tabs[i].label}, selected',
                  child: _TabIcon(
                    icon: tabs[i].selected,
                    badgeCount: i == MainShellScreen.moreTabIndex ? unreadCount : 0,
                  ),
                ),
                label: tabs[i].label,
                tooltip: tabs[i].label,
              ),
          ],
        ),
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
    return Badge(
      label: Text(label),
      backgroundColor: palette.primary,
      textColor: palette.onPrimary,
      child: Icon(icon),
    );
  }
}
