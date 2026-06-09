import 'package:flutter/material.dart';

import '../theme/accessibility_scope.dart';
import '../theme/udaan_text_styles.dart';

/// Dark Udaan app bar used on main tabs.
class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BrandAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.centerTitle = false,
  });

  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;
    return AppBar(
      backgroundColor: palette.background,
      foregroundColor: palette.onBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      leading: leading,
      automaticallyImplyLeading: leading == null,
      title: Text(
        title,
        style: udaanTextStyle(
          context,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: palette.primaryGlow,
        ),
      ),
      actions: actions,
    );
  }
}
