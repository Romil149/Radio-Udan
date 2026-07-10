import '../../../core/config/app_branding.dart';
import '../../../core/config/app_copy_accessors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/udaan_colors.dart';
import '../../../core/utils/phone_e164.dart';
import 'udaan_auth_widgets.dart';
import 'udaan_otp_pin_row.dart';

/// Registration phone OTP UI (Stitch “Verify Identity”).
class OtpVerifyIdentityBody extends StatelessWidget {
  const OtpVerifyIdentityBody({
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
    required this.onContactSupport,
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
  final VoidCallback? onContactSupport;

  static const int otpLength = 6;

  @override
  Widget build(BuildContext context) {
    final maskedPhone = maskPhoneForOtpDisplay(phoneE164);
    final bodyStyle = GoogleFonts.atkinsonHyperlegible(
      fontSize: 17,
      fontWeight: FontWeight.w500,
      color: context.udaan.onBackground.withValues(alpha: 0.92),
      height: 1.4,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UdaanAuthTopBar(
          copy: copy,
          title: copy.verifyIdentityTitle,
          onBack: onBack,
          trailing: ExcludeSemantics(
            child: Icon(
              Icons.verified_user_outlined,
              color: context.udaan.primaryGlow.withValues(alpha: 0.95),
              size: 26,
            ),
          ),
        ),
        Divider(
          height: 24,
          thickness: 1,
          color: context.udaan.outlineVariant,
        ),
        const SizedBox(height: 8),
        Center(
          child: UdaanOtpPadlockHero(
            copy: copy,
          ),
        ),
        const SizedBox(height: 28),
        ExcludeSemantics(
          child: Text(
            copy.verifyIdentityTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: context.udaan.onBackground,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Semantics(
          label: '${copy.verifyIdentityIntro} $maskedPhone',
          child: ExcludeSemantics(
            child: Column(
              children: [
                Text(
                  copy.verifyIdentityIntro,
                  textAlign: TextAlign.center,
                  style: bodyStyle,
                ),
                const SizedBox(height: 8),
                Text(
                  maskedPhone,
                  textAlign: TextAlign.center,
                  style: bodyStyle.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.udaan.primaryGlow,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (kDebugMode && devOtp != null) ...[
          const SizedBox(height: 8),
          Semantics(
            label: copy.verifyDevHint,
            child: ExcludeSemantics(
              child: Text(
                copy.verifyDevHint,
                textAlign: TextAlign.center,
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 14,
                  color: context.udaan.onSurfaceVariant,
                ),
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
            child: ExcludeSemantics(
              child: Text(
                error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.udaan.error,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 32),
        UdaanPrimaryButton(
          label: copy.verifyButton,
          icon: Icons.check_circle_outline,
          loading: loading,
          onPressed: loading ? null : onVerify,
        ),
        if (resendSecondsRemaining > 0) ...[
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            label:
                '${copy.otpWaitPrompt}${copy.otpWaitTimer(resendSecondsRemaining)}',
            child: ExcludeSemantics(
              child: Text(
                '${copy.otpWaitPrompt}${copy.otpWaitTimer(resendSecondsRemaining)}',
                textAlign: TextAlign.center,
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.udaan.primaryGlow,
                ),
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
        const SizedBox(height: 28),
        UdaanContactSupportPrompt(
          copy: copy,
          onContactSupport: onContactSupport,
        ),
      ],
    );
  }
}
