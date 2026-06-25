import '../../../core/config/app_branding.dart';
import '../../../core/config/app_copy_accessors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/udaan_colors.dart';
import '../../../core/utils/phone_e164.dart';
import 'udaan_auth_widgets.dart';
import 'udaan_otp_pin_row.dart';

/// Login OTP UI (Stitch “Enter OTP” / READY TO LAUNCH flow).
class OtpVerifyLoginBody extends StatelessWidget {
  const OtpVerifyLoginBody({
    required this.copy,
    required this.brandingAppName,
    required this.phoneE164,
    required this.otpController,
    required this.error,
    required this.loading,
    required this.resending,
    required this.canResend,
    required this.resendSecondsRemaining,
    required this.devOtp,
    required this.onBack,
    required this.onVerify,
    required this.onResend,
    super.key,
  });

  final AppCopy copy;
  final String brandingAppName;
  final String phoneE164;
  final TextEditingController otpController;
  final String? error;
  final bool loading;
  final bool resending;
  final bool canResend;
  final int resendSecondsRemaining;
  final String? devOtp;
  final VoidCallback onBack;
  final VoidCallback onVerify;
  final VoidCallback? onResend;

  static const int otpLength = 6;

  @override
  Widget build(BuildContext context) {
    final maskedPhone = maskPhoneForOtpDisplay(phoneE164);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UdaanAuthTopBar(
                copy: copy,
                title: brandingAppName,
          onBack: onBack,
        ),
        const SizedBox(height: 24),
        Center(child: UdaanOtpHeroIcon(
                copy: copy,
                )),
        const SizedBox(height: 28),
        Semantics(
          header: true,
          label: copy.otpEnterTitle,
          child: Text(
            copy.otpEnterTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: UdaanColors.onBackground,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          copy.otpSentIntro,
          textAlign: TextAlign.center,
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: UdaanColors.onBackground.withValues(alpha: 0.9),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          maskedPhone,
          textAlign: TextAlign.center,
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: UdaanColors.onBackground,
          ),
        ),
        if (kDebugMode && devOtp != null) ...[
          const SizedBox(height: 8),
          Semantics(
            label: copy.verifyDevHint,
            child: Text(
              copy.verifyDevHint,
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
                copy: copy,
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
          label: copy.otpLoginButton,
          icon: Icons.login_rounded,
          loading: loading,
          onPressed: loading ? null : onVerify,
        ),
        if (resendSecondsRemaining > 0) ...[
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            label:
                '${copy.otpWaitPrompt}${copy.otpWaitTimer(resendSecondsRemaining)}',
            child: Text(
              '${copy.otpWaitPrompt}${copy.otpWaitTimer(resendSecondsRemaining)}',
              textAlign: TextAlign.center,
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: UdaanColors.primaryGlow,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        UdaanOutlineButton(
          label: copy.otpResendLabel,
          icon: Icons.refresh,
          loading: resending,
          onPressed: canResend && !resending ? onResend : null,
        ),
      ],
    );
  }
}
