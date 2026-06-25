import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/network/dio_exception_mapper.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/udaan_colors.dart';
import '../../core/utils/phone_e164.dart';
import 'auth_validators.dart';
import 'widgets/udaan_auth_widgets.dart';
import 'widgets/udaan_otp_pin_row.dart';

/// Sets a new password using email token or SMS OTP + phone from reset flow.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({
    this.initialToken,
    this.phoneE164,
    this.otp,
    super.key,
  });

  final String? initialToken;
  final String? phoneE164;
  final String? otp;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  AppCopy get _copy => ref.read(appCopyProvider);

  late final TextEditingController _tokenController;
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  bool get _smsReset =>
      widget.phoneE164 != null &&
      widget.phoneE164!.isNotEmpty &&
      widget.otp != null &&
      widget.otp!.isNotEmpty;

  int get _passwordMinLength =>
      ref.read(remoteConfigProvider)?.authPolicy.passwordMinLength ?? 8;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.initialToken ?? '');
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _announce(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      );
    });
  }

  Widget _visibilityToggle({
    required bool obscured,
    required VoidCallback onToggle,
  }) {
    return Semantics(
      button: true,
      label: obscured ? _copy.showPassword : _copy.hidePassword,
      child: IconButton(
        icon: Icon(
          obscured
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: UdaanColors.primaryGlow,
        ),
        onPressed: onToggle,
      ),
    );
  }

  Future<void> _submit() async {
    final token = _tokenController.text.trim();
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    final minLen = _passwordMinLength;

    if (!_smsReset && token.isEmpty) {
      setState(() => _error = _copy.resetTokenRequired);
      _announce(_copy.resetTokenRequired);
      return;
    }
    if (!_smsReset && code.length != 6) {
      setState(() => _error = _copy.resetEmailCodeRequired);
      _announce(_copy.resetEmailCodeRequired);
      return;
    }
    if (!isValidPassword(password, minLength: minLen)) {
      setState(() => _error = _copy.passwordTooShort);
      _announce(_copy.passwordTooShort);
      return;
    }
    if (password != confirm) {
      setState(() => _error = _copy.passwordMismatch);
      _announce(_copy.passwordMismatch);
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      await ref.read(radioudaanApiProvider).resetPassword(
            token: _smsReset ? null : token,
            code: _smsReset ? null : code,
            phoneE164: widget.phoneE164,
            otp: widget.otp,
            password: password,
          );
      if (!mounted) return;
      _announce(_copy.resetPasswordSuccess);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_copy.resetPasswordSuccess)),
      );
      context.go('/login');
    } catch (e) {
      final message = parseApiError(e).message;
      setState(() => _error = message);
      _announce(message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = ref.watch(appCopyProvider);
    final branding = ref.watch(appBrandingProvider);
    final tokenFromLink = widget.initialToken != null &&
        widget.initialToken!.isNotEmpty;
    final intro = _smsReset
        ? _copy.resetPasswordSmsIntro(
            maskPhoneForOtpDisplay(widget.phoneE164),
          )
        : _copy.resetPasswordIntro;
    final passwordHint = _copy.passwordMinHint(_passwordMinLength);

    return Scaffold(
      backgroundColor: UdaanColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UdaanAuthTopBar(
                copy: copy,
                title: branding.appName,
                onBack: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/login');
                  }
                },
              ),
              const Divider(
                height: 24,
                thickness: 1,
                color: UdaanColors.outlineVariant,
              ),
              const SizedBox(height: 8),
              Center(child: UdaanForgotPasswordHero(
                copy: copy,
                )),
              const SizedBox(height: 28),
              Semantics(
                header: true,
                label: _copy.resetPasswordTitle,
                child: Text(
                  _copy.resetPasswordTitle,
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
                intro,
                textAlign: TextAlign.center,
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: UdaanColors.primaryGlow,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 28),
              if (!_smsReset && !tokenFromLink) ...[
                UdaanLabeledField(
                  label: _copy.resetTokenLabel,
                  controller: _tokenController,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.link,
                  required: true,
                ),
                const SizedBox(height: 20),
              ],
              if (!_smsReset) ...[
                UdaanOtpPinRow(
                copy: copy,
                controller: _codeController,
                  length: 6,
                  enabled: !_loading,
                  semanticsHint: _copy.otpPinRowEmailHint(6),
                ),
                const SizedBox(height: 24),
              ],
              UdaanLabeledField(
                label: _copy.passwordLabel,
                controller: _passwordController,
                hint: passwordHint,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.lock_outline,
                autofillHints: const [AutofillHints.newPassword],
                required: true,
                suffixIcon: _visibilityToggle(
                  obscured: _obscurePassword,
                  onToggle: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 20),
              UdaanLabeledField(
                label: _copy.confirmPasswordLabel,
                controller: _confirmController,
                hint: _copy.registerConfirmHint,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                prefixIcon: Icons.lock_outline,
                autofillHints: const [AutofillHints.newPassword],
                required: true,
                suffixIcon: _visibilityToggle(
                  obscured: _obscureConfirm,
                  onToggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                onSubmitted: (_) => _loading ? null : _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  label: _error,
                  liveRegion: true,
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: UdaanColors.error,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              UdaanPrimaryButton(
                label: _copy.resetPassword,
                icon: Icons.lock_reset_rounded,
                loading: _loading,
                onPressed: _loading ? null : _submit,
              ),
              const SizedBox(height: 16),
              Semantics(
                button: true,
                label: _copy.backToLogin,
                child: TextButton.icon(
                  onPressed: _loading ? null : () => context.go('/login'),
                  icon: const Icon(
                    Icons.chevron_left,
                    color: UdaanColors.secondary,
                  ),
                  label: Text(
                    _copy.backToLogin,
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: UdaanColors.secondary,
                    ),
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
