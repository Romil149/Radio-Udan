import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'brand_app_bar.dart';

/// Top bar for main shell tabs: centered page title only (More is a bottom tab).
class MainTabAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const MainTabAppBar({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BrandAppBar(
      title: title,
      centerTitle: true,
      automaticallyImplyLeading: false,
    );
  }
}
