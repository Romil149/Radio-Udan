import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/brand_tokens.dart';
import 'app_bar_brand_logo.dart';
import 'brand_app_bar.dart';

/// Top bar for main shell tabs: logo (left) + centered page title.
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
      leading: const SizedBox(
        width: BrandTokens.a11yMinTapTarget + 20,
        child: Align(
          alignment: Alignment.centerLeft,
          child: AppBarBrandLogo(),
        ),
      ),
    );
  }
}
