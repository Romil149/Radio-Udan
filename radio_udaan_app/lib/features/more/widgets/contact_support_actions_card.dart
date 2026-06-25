import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_branding.dart';
import '../../../core/config/app_copy_accessors.dart';
import '../../../core/theme/brand_tokens.dart';
import '../../../core/theme/udaan_colors.dart';
import '../../auth/widgets/udaan_auth_widgets.dart';

/// "Still need help?" card with email + helpline actions (Contact screen footer).
class ContactSupportActionsCard extends StatelessWidget {
  const ContactSupportActionsCard({
    super.key,
    required this.copy,
    required this.supportEmail,
    required this.helplinePhone,
    this.onLaunchFailed,
  });

  final AppCopy copy;
  final String supportEmail;
  final String helplinePhone;
  final VoidCallback? onLaunchFailed;

  Future<void> _launch(BuildContext context, Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      onLaunchFailed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasEmail = supportEmail.trim().isNotEmpty;
    final hasPhone = helplinePhone.trim().isNotEmpty;

    if (!hasEmail && !hasPhone) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BrandTokens.screenPadding),
      decoration: BoxDecoration(
        color: UdaanColors.surfaceContainer,
        borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
        border: Border.all(color: UdaanColors.primaryGlow, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              copy.stillNeedHelp,
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: UdaanColors.primaryGlow,
              ),
            ),
          ),
          if (hasEmail) ...[
            const SizedBox(height: 16),
            UdaanPrimaryButton(
              label: copy.emailSupport,
              icon: Icons.mail_outline,
              onPressed: () => _launch(
                context,
                Uri(scheme: 'mailto', path: supportEmail.trim()),
              ),
            ),
          ],
          if (hasPhone) ...[
            const SizedBox(height: 12),
            UdaanOutlineButton(
              label: copy.callAccessibilityHelpline,
              icon: Icons.phone,
              onPressed: () => _launch(
                context,
                Uri(scheme: 'tel', path: helplinePhone.trim()),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
