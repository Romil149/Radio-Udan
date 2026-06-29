import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/app_providers.dart';
import '../theme/brand_tokens.dart';
import '../theme/udaan_colors.dart';

/// Accessible pre-prompt before the OS notification permission dialog.
class NotificationPermissionPromptSheet extends ConsumerWidget {
  const NotificationPermissionPromptSheet({
    super.key,
    required this.onContinue,
    required this.onNotNow,
  });

  final Future<void> Function() onContinue;
  final Future<void> Function() onNotNow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = ref.watch(appCopyProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      child: Container(
        decoration: BoxDecoration(
          color: context.udaan.surfaceContainer,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(
          BrandTokens.screenPadding,
          20,
          BrandTokens.screenPadding,
          16 + bottomInset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              label: copy.notificationPermissionTitle,
              child: ExcludeSemantics(
                child: Text(
                  copy.notificationPermissionTitle,
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: context.udaan.primaryGlow,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              copy.notificationPermissionBody,
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: context.udaan.onBackground,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            Semantics(
              button: true,
              label: copy.notificationPermissionContinue,
              child: ExcludeSemantics(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(
                      BrandTokens.a11yMinTapTarget,
                    ),
                    backgroundColor: context.udaan.primary,
                    foregroundColor: context.udaan.onPrimary,
                  ),
                  onPressed: () => onContinue(),
                  child: Text(copy.notificationPermissionContinue),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Semantics(
              button: true,
              label: copy.notificationPermissionNotNow,
              child: ExcludeSemantics(
                child: TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(
                      BrandTokens.a11yMinTapTarget,
                    ),
                  ),
                  onPressed: () => onNotNow(),
                  child: Text(copy.notificationPermissionNotNow),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
