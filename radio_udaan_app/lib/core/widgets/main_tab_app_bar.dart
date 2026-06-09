import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_strings.dart';
import '../providers/app_providers.dart';
import '../theme/brand_tokens.dart';
import '../../features/shell/main_shell_screen.dart';
import 'brand_app_bar.dart';

/// Top bar for main shell tabs: menu (More) · page title · profile.
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
    return BrandAppBar(
      title: title,
      centerTitle: true,
      leading: Semantics(
        button: true,
        label: AppStrings.tabMore,
        child: IconButton(
          constraints: const BoxConstraints(
            minWidth: BrandTokens.a11yMinTapTarget,
            minHeight: BrandTokens.a11yMinTapTarget,
          ),
          onPressed: () => _openMoreTab(ref),
          icon: const Icon(Icons.menu),
        ),
      ),
      actions: [
        Semantics(
          button: true,
          label: onProfileTap != null ? AppStrings.profile : AppStrings.tabMore,
          child: IconButton(
            constraints: const BoxConstraints(
              minWidth: BrandTokens.a11yMinTapTarget,
              minHeight: BrandTokens.a11yMinTapTarget,
            ),
            onPressed: onProfileTap ?? () => _openMoreTab(ref),
            icon: const Icon(Icons.person_outline),
          ),
        ),
      ],
    );
  }
}
