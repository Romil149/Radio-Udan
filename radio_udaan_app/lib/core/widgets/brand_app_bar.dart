import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibility/udaan_semantics.dart';
import '../providers/app_providers.dart';
import '../theme/accessibility_scope.dart';
import '../theme/brand_tokens.dart';
import '../theme/udaan_text_styles.dart';

/// Dark Udaan app bar for pushed screens and main tabs.
class BrandAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const BrandAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.centerTitle = false,
    this.automaticallyImplyLeading,
  });

  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool? automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.udaan;
    final copy = ref.watch(appCopyProvider);
    final canPop = Navigator.canPop(context);
    final showBack = automaticallyImplyLeading ?? canPop;

    Widget? resolvedLeading = leading;
    if (resolvedLeading == null && showBack && canPop) {
      resolvedLeading = Semantics(
        button: true,
        label: copy.backButton,
        child: ExcludeSemantics(
          child: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            constraints: const BoxConstraints(
              minWidth: BrandTokens.a11yMinTapTarget,
              minHeight: BrandTokens.a11yMinTapTarget,
            ),
            icon: Icon(Icons.arrow_back, color: palette.onBackground),
          ),
        ),
      );
    }

    return AppBar(
      backgroundColor: palette.background,
      foregroundColor: palette.onBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      leading: resolvedLeading,
      automaticallyImplyLeading: false,
      title: UdaanScreenHeader(
        title: title,
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
