import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/udaan_colors.dart';
import '../../../core/utils/phone_e164.dart';
import 'udaan_auth_widgets.dart';
import 'udaan_otp_pin_row.dart';

/// Registration phone OTP UI (Stitch “Verify Identity”).
class OtpVerifyIdentityBody extends StatelessWidget {
  const OtpVerifyIdentityBody({
    required this.brandingAppName,
    required this.phoneE164,
    required this.otpController,
    required this.error,
    required this.loading,
    required this.resending,
    required this.canResend,
    required this.devOtp,
    required this.onBack,
    required this.onVerify,
    required this.onResend,
    required this.onContactSupport,
    super.key,
  });

  final String brandingAppName;
  final String phoneE164;
  final TextEditingController otpController;
  final String? error;
  final bool loading;
  final bool resending;
  final bool canResend;
  final String? devOtp;
  final VoidCallback onBack;
  final VoidCallback onVerify;
  final VoidCallback? onResend;
  final VoidCallback? onContactSupport;

  static const int otpLength = 6;

  @override
  Widget build(BuildContext context) {
    final maskedPhone = maskPhoneForOtpDisplay(phoneE164);
    final bodyStyle = GoogleFonts.atkinsonHyperlegible(
      fontSize: 17,
      fontWeight: FontWeight.w500,
      color: UdaanColors.onBackground.withValues(alpha: 0.92),
      height: 1.4,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UdaanAuthTopBar(
          title: brandingAppName,
          onBack: onBack,
          trailing: Semantics(
            label: AppStrings.secureVerificationHero,
            child: Icon(
              Icons.verified_user_outlined,
              color: UdaanColors.primaryGlow.withValues(alpha: 0.95),
              size: 26,
            ),
          ),
        ),
        const Divider(
          height: 24,
          thickness: 1,
          color: UdaanColors.outlineVariant,
        ),
        const SizedBox(height: 8),
        const Center(child: UdaanOtpPadlockHero()),
        const SizedBox(height: 28),
        Semantics(
          header: true,
          label: AppStrings.verifyIdentityTitle,
          child: Text(
            AppStrings.verifyIdentityTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: UdaanColors.onBackground,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Semantics(
          label: '${AppStrings.verifyIdentityIntro} $maskedPhone',
          child: Column(
            children: [
              Text(
                AppStrings.verifyIdentityIntro,
                textAlign: TextAlign.center,
                style: bodyStyle,
              ),
              const SizedBox(height: 8),
              Text(
                maskedPhone,
                textAlign: TextAlign.center,
                style: bodyStyle.copyWith(
                  fontWeight: FontWeight.w800,
                  color: UdaanColors.primaryGlow,
                ),
              ),
            ],
          ),
        ),
        if (kDebugMode && devOtp != null) ...[
          const SizedBox(height: 8),
          Semantics(
            label: AppStrings.verifyDevHint,
            child: Text(
              AppStrings.verifyDevHint,
              textAlign: TextAlign.center,
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 14,
                color: UdaanColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
        const SizedBox(height: 28),
        UdaanOtpPinRow(
          controller: otpController,
          length: otpLength,
          enabled: !loading && !resending,
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Semantics(
            label: error,
            liveRegion: true,
            child: Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: UdaanColors.error,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(height: 32),
        UdaanPrimaryButton(
          label: AppStrings.verifyButton,
          icon: Icons.check_circle_outline,
          loading: loading,
          onPressed: loading ? null : onVerify,
        ),
        const SizedBox(height: 16),
        UdaanOutlineButton(
          label: AppStrings.otpResendLabel,
          icon: Icons.refresh,
          loading: resending,
          onPressed: canResend && !resending ? onResend : null,
        ),
        const SizedBox(height: 28),
        UdaanContactSupportPrompt(onContactSupport: onContactSupport),
      ],
    );
  }
}
