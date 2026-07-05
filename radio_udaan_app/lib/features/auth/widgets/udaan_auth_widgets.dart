import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/config/app_branding.dart';
import '../../../core/config/app_copy_accessors.dart';
import '../../../core/theme/accessibility_scope.dart';
import '../../../core/theme/brand_tokens.dart';
import '../../../core/theme/udaan_colors.dart';
import '../../../core/theme/udaan_text_styles.dart';
import '../../../core/utils/keyboard_dismiss.dart';
import '../../../core/widgets/offline_brand_logo.dart';

/// Top bar: back + centered app title (OTP verify and similar flows).
class UdaanAuthTopBar extends StatelessWidget {
  const UdaanAuthTopBar({
    required this.copy,
    required this.title,
    required this.onBack,
    this.trailing,
    super.key,
  });

  final AppCopy copy;
  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Semantics(
              button: true,
              label: copy.backButton,
              child: ExcludeSemantics(
                child: IconButton(
                  onPressed: onBack,
                  constraints: const BoxConstraints(
                    minWidth: BrandTokens.a11yMinTapTarget,
                    minHeight: BrandTokens.a11yMinTapTarget,
                  ),
                  icon: Icon(
                    Icons.arrow_back,
                    color: palette.onBackground,
                  ),
                ),
              ),
            ),
          ),
          Semantics(
            header: true,
            label: title,
            child: ExcludeSemantics(
              child: Text(
                title,
                style: udaanTextStyle(
                  context,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: palette.primaryGlow,
                ),
              ),
            ),
          ),
          if (trailing != null)
            Align(
              alignment: Alignment.centerRight,
              child: trailing,
            ),
        ],
      ),
    );
  }
}

/// Orange circle with lock-reset icon (forgot password).
/// Email verification hero (verify email screen).
class UdaanVerifyEmailHero extends StatelessWidget {
  const UdaanVerifyEmailHero({required this.copy, super.key});

  final AppCopy copy;

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;
    return Semantics(
      label: copy.verifyEmailTitle,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: palette.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.mark_email_read_outlined,
          size: 56,
          color: palette.onPrimary,
        ),
      ),
    );
  }
}

class UdaanForgotPasswordHero extends StatelessWidget {
  const UdaanForgotPasswordHero({required this.copy, super.key});

  final AppCopy copy;

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;
    return Semantics(
      label: copy.resetPasswordHero,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: palette.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.lock_reset_rounded,
          size: 56,
          color: palette.onPrimary,
        ),
      ),
    );
  }
}

/// Forgot-password accessibility / support callout.
class UdaanForgotPasswordHelpCard extends StatelessWidget {
  const UdaanForgotPasswordHelpCard({required this.copy, super.key});

  final AppCopy copy;

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;
    return Semantics(
      container: true,
      label: copy.forgotPasswordHelpBody,
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surfaceContainer.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: palette.primaryGlow.withValues(alpha: 0.95),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  copy.forgotPasswordHelpBody,
                  style: udaanTextStyle(
                    context,
                    fontSize: 14,
                    height: 1.45,
                    color: palette.onBackground.withValues(alpha: 0.88),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Outlined circle with padlock (registration OTP / Verify Identity).
class UdaanOtpPadlockHero extends StatelessWidget {
  const UdaanOtpPadlockHero({required this.copy, super.key});

  final AppCopy copy;

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;
    return Semantics(
      label: copy.verifyIdentityHero,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: palette.primaryGlow, width: 2.5),
        ),
        child: Icon(
          Icons.lock_open_rounded,
          size: 52,
          color: palette.primaryGlow,
        ),
      ),
    );
  }
}

/// Orange circle with shield icon (OTP verify hero).
class UdaanOtpHeroIcon extends StatelessWidget {
  const UdaanOtpHeroIcon({required this.copy, super.key});

  final AppCopy copy;

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;
    return Semantics(
      label: copy.secureVerificationHero,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: palette.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.verified_user,
          size: 56,
          color: palette.onPrimary,
        ),
      ),
    );
  }
}

/// Shared Stitch Udaan Core auth chrome (`stitch/login_with_otp_option`).
class UdaanAuthLogoHeader extends StatelessWidget {
  const UdaanAuthLogoHeader({
    required this.branding,
    this.subtitle,
    this.showAppNameHeader = true,
    super.key,
  });

  final AppBranding branding;
  final String? subtitle;
  final bool showAppNameHeader;

  static const double _logoHeight = 120;

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;
    return Column(
      children: [
        OfflineBrandLogo(branding: branding, height: _logoHeight),
        if (showAppNameHeader) ...[
          const SizedBox(height: 20),
          Semantics(
            header: true,
            label: branding.appName,
            child: ExcludeSemantics(
              child: Text(
                branding.appName,
                textAlign: TextAlign.center,
                style: udaanTextStyle(
                  context,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: palette.primaryGlow,
                  height: 1.15,
                ),
              ),
            ),
          ),
        ] else
          const SizedBox(height: 20),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: udaanTextStyle(
              context,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: palette.onBackground.withValues(alpha: 0.92),
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

class UdaanLabeledField extends StatelessWidget {
  const UdaanLabeledField({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.autofillHints,
    this.prefixIcon,
    this.prefixText,
    this.suffixIcon,
    this.inputFormatters,
    this.onSubmitted,
    this.readOnly = false,
    this.required = false,
    this.semanticsLabel,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool readOnly;
  final bool required;
  final String? semanticsLabel;
  final Iterable<String>? autofillHints;
  final IconData? prefixIcon;
  final String? prefixText;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onSubmitted;

  String get _fieldSemanticsLabel {
    if (semanticsLabel != null && semanticsLabel!.isNotEmpty) {
      return semanticsLabel!;
    }
    if (required) return '$label, required';
    return label;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text(
            label,
            style: udaanTextStyle(
              context,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: palette.onBackground,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (suffixIcon == null)
          Semantics(
            textField: true,
            label: _fieldSemanticsLabel,
            readOnly: readOnly,
            obscured: obscureText,
            child: ExcludeSemantics(
              child: _buildTextField(context, palette),
            ),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Semantics(
                  textField: true,
                  label: _fieldSemanticsLabel,
                  readOnly: readOnly,
                  obscured: obscureText,
                  child: ExcludeSemantics(
                    child: _buildTextField(context, palette),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: BrandTokens.a11yMinTapTarget,
                height: BrandTokens.a11yMinTapTarget,
                child: Center(child: suffixIcon!),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTextField(BuildContext context, UdaanPalette palette) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      onSubmitted: (value) {
        dismissKeyboard(context);
        onSubmitted?.call(value);
      },
      onTapOutside: (_) => dismissKeyboard(context),
      style: udaanTextStyle(
        context,
        fontSize: 18,
        color: palette.onBackground,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: udaanTextStyle(
          context,
          fontSize: 18,
          color: palette.hint,
        ),
        filled: true,
        fillColor: palette.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: palette.primaryGlow, size: 22)
            : null,
        prefixText: prefixText,
        prefixStyle: udaanTextStyle(
          context,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: palette.onBackground,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.primaryGlow),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: palette.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.error, width: 2),
        ),
      ),
    );
  }
}

class UdaanPrimaryButton extends StatelessWidget {
  const UdaanPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;
    return Semantics(
      button: true,
      label: label,
      enabled: onPressed != null && !loading,
      child: ExcludeSemantics(
        child: FilledButton(
          onPressed: loading
              ? null
              : () {
                  dismissKeyboard(context);
                  onPressed?.call();
                },
          style: FilledButton.styleFrom(
            backgroundColor: palette.primary,
            foregroundColor: palette.onPrimary,
            disabledBackgroundColor: palette.primary.withValues(alpha: 0.5),
            minimumSize: const Size.fromHeight(56),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: loading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: palette.onPrimary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 22),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    label,
                    style: udaanTextStyle(
                      context,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: palette.onPrimary,
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}

class UdaanOutlineButton extends StatelessWidget {
  const UdaanOutlineButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;
    return Semantics(
      button: true,
      label: label,
      enabled: onPressed != null && !loading,
      child: ExcludeSemantics(
        child: OutlinedButton(
          onPressed: loading
              ? null
              : () {
                  dismissKeyboard(context);
                  onPressed?.call();
                },
          style: OutlinedButton.styleFrom(
            foregroundColor: palette.primaryGlow,
            side: BorderSide(color: palette.primaryGlow, width: 1.5),
            minimumSize: const Size.fromHeight(56),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: loading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: palette.primaryGlow,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 22, color: palette.primaryGlow),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    label,
                    style: udaanTextStyle(
                      context,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: palette.primaryGlow,
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}

class UdaanAuthLink extends StatelessWidget {
  const UdaanAuthLink({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;
    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: TextButton(
          onPressed: () {
            dismissKeyboard(context);
            onPressed?.call();
          },
          style: TextButton.styleFrom(
            foregroundColor: palette.primaryGlow,
            padding: EdgeInsets.zero,
            minimumSize: const Size(
              BrandTokens.a11yMinTapTarget,
              BrandTokens.a11yMinTapTarget,
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            label,
            style: udaanTextStyle(
              context,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: palette.primaryGlow,
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo only (register and similar screens with a separate headline).
class UdaanAuthCompactLogo extends StatelessWidget {
  const UdaanAuthCompactLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return OfflineBrandLogo(
      branding: AppBranding.defaults,
      height: 100,
    );
  }
}

/// Stitch register screen accessibility callout.
class UdaanAccessibilityAssistCard extends StatelessWidget {
  const UdaanAccessibilityAssistCard({required this.copy, super.key});

  final AppCopy copy;

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;
    return Semantics(
      container: true,
      label: '${copy.registerA11yTitle}. ${copy.registerA11yBody}',
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surfaceContainer.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: palette.secondary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    copy.registerA11yTitle,
                    style: udaanTextStyle(
                      context,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: palette.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                copy.registerA11yBody,
                style: udaanTextStyle(
                  context,
                  fontSize: 14,
                  height: 1.45,
                  color: palette.onBackground.withValues(alpha: 0.88),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline prompt + underlined action (register footer).
/// Footer link for OTP / support (registration verify identity).
class UdaanContactSupportPrompt extends StatelessWidget {
  const UdaanContactSupportPrompt({
    required this.copy,
    required this.onContactSupport,
    super.key,
  });

  final AppCopy copy;
  final VoidCallback? onContactSupport;

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '${copy.otpHavingTrouble} ',
            style: udaanTextStyle(
              context,
              fontSize: 16,
              color: palette.primaryGlow.withValues(alpha: 0.9),
            ),
          ),
          Semantics(
            button: true,
            label: copy.contactSupport,
            child: ExcludeSemantics(
              child: TextButton(
                onPressed: () {
                  dismissKeyboard(context);
                  onContactSupport?.call();
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(
                    BrandTokens.a11yMinTapTarget,
                    BrandTokens.a11yMinTapTarget,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  copy.contactSupport,
                  style: udaanTextStyle(
                    context,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: palette.primaryGlow,
                  ).copyWith(
                    decoration: TextDecoration.underline,
                    decorationColor: palette.primaryGlow,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UdaanSignInPrompt extends StatelessWidget {
  const UdaanSignInPrompt({
    required this.copy,
    required this.onSignIn,
    super.key,
  });

  final AppCopy copy;
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '${copy.hasAccountPrompt} ',
            style: udaanTextStyle(
              context,
              fontSize: 16,
              color: palette.onBackground.withValues(alpha: 0.85),
            ),
          ),
          Semantics(
            button: true,
            label: copy.signInHere,
            child: ExcludeSemantics(
              child: TextButton(
                onPressed: () {
                  dismissKeyboard(context);
                  onSignIn?.call();
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(
                    BrandTokens.a11yMinTapTarget,
                    BrandTokens.a11yMinTapTarget,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  copy.signInHere,
                  style: udaanTextStyle(
                    context,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: palette.primaryGlow,
                  ).copyWith(
                    decoration: TextDecoration.underline,
                    decorationColor: palette.primaryGlow,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UdaanAuthFooterPrompt extends StatelessWidget {
  const UdaanAuthFooterPrompt({
    required this.prompt,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final String prompt;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;
    return Column(
      children: [
        Text(
          prompt,
          textAlign: TextAlign.center,
          style: udaanTextStyle(
            context,
            fontSize: 16,
            color: palette.onBackground.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 6),
        Semantics(
          button: true,
          label: actionLabel,
          child: ExcludeSemantics(
            child: TextButton(
              onPressed: () {
                dismissKeyboard(context);
                onAction?.call();
              },
              style: TextButton.styleFrom(
                minimumSize: const Size(
                  BrandTokens.a11yMinTapTarget,
                  BrandTokens.a11yMinTapTarget,
                ),
              ),
              child: Text(
                actionLabel,
                style: udaanTextStyle(
                  context,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: palette.primaryGlow,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
