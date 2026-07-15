import 'package:flutter/material.dart';

import '../../../core/config/app_branding.dart';
import '../../../core/config/app_copy_accessors.dart';
import '../../../core/theme/accessibility_scope.dart';
import '../../../core/theme/brand_tokens.dart';
import '../../../core/theme/udaan_google_fonts.dart';
import '../../../core/utils/external_link.dart';
import '../../auth/widgets/udaan_auth_widgets.dart';

/// iOS/iPad App Store–compliant donate: opens Razorpay payment page in Safari.
///
/// No amount chips, orders, or in-app checkout — Safari link-out only.
class DonateSafariLinkCard extends StatelessWidget {
  const DonateSafariLinkCard({
    required this.copy,
    required this.paymentUrl,
    super.key,
  });

  final AppCopy copy;
  final String paymentUrl;

  Future<void> _openSafari(BuildContext context) async {
    await openExternalUrl(context, paymentUrl, copy: copy);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BrandTokens.screenPadding),
      decoration: BoxDecoration(
        color: palette.surfaceContainer,
        borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
        border: Border.all(color: palette.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: ExcludeSemantics(
              child: Text(
                copy.donateSafariTitle,
                style: udaanGoogleFont(
                  context,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: palette.onBackground,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            copy.donateSafariSubtitle,
            style: udaanGoogleFont(
              context,
              fontSize: 15,
              height: 1.45,
              color: palette.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          UdaanPrimaryButton(
            label: copy.donateSafariButton,
            icon: Icons.open_in_browser,
            semanticsLabel: copy.donateSafariButtonSemantics,
            onPressed: () => _openSafari(context),
          ),
        ],
      ),
    );
  }
}
