import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../theme/brand_tokens.dart';
import '../../features/shell/main_shell_screen.dart';
import 'brand_app_bar.dart';

/// Top bar for main shell tabs: page title · profile (More is bottom tab only).
class MainTabAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final VoidCallback? onProfileTap;

  const MainTabAppBar({
    super.key,
    required this.title,
    this.onProfileTap,
  });

  final String title;

  void _openMoreTab(WidgetRef ref) {
    ref.read(mainShellTabIndexProvider.notifier).state =
        MainShellScreen.moreTabIndex;
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = ref.watch(appCopyProvider);
    return BrandAppBar(
      title: title,
      centerTitle: true,
      automaticallyImplyLeading: false,
      actions: [
        Semantics(
          button: true,
          label: onProfileTap != null ? copy.profile : copy.tabMore,
          child: ExcludeSemantics(
            child: IconButton(
              constraints: const BoxConstraints(
                minWidth: BrandTokens.a11yMinTapTarget,
                minHeight: BrandTokens.a11yMinTapTarget,
              ),
              onPressed: onProfileTap ?? () => _openMoreTab(ref),
              icon: const Icon(Icons.person_outline),
            ),
          ),
        ),
      ],
    );
  }
}
