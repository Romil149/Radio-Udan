import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/otp_purpose.dart';
import '../../core/network/dio_exception_mapper.dart';
import '../../core/providers/app_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/udaan_colors.dart';
import 'auth_validators.dart';
import 'widgets/udaan_auth_widgets.dart';
import 'widgets/udaan_phone_field.dart';

/// New account registration (Stitch register screen).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  AppCopy get _copy => ref.read(appCopyProvider);

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneInput = PhoneCountryInputController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  int get _passwordMinLength =>
      ref.read(remoteConfigProvider)?.authPolicy.passwordMinLength ?? 8;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneInput.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Widget _visibilityToggle({
    required bool obscured,
    required VoidCallback onToggle,
  }) {
    return Semantics(
      button: true,
      label: obscured ? _copy.showPassword : _copy.hidePassword,
      child: ExcludeSemantics(
        child: IconButton(
          icon: Icon(
            obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: context.udaan.primaryGlow,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final phone = _phoneInput.e164;
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    final minLen = _passwordMinLength;

    if (name.isEmpty) {
      setState(() => _error = _copy.nameRequired);
      return;
    }
    if (!isValidEmail(email)) {
      setState(() => _error = _copy.emailInvalid);
      return;
    }
    if (phone == null) {
      setState(() => _error = _copy.phoneInvalid);
      return;
    }
    if (!isValidPassword(password, minLength: minLen)) {
      setState(() => _error = _copy.passwordTooShort);
      return;
    }
    if (password != confirm) {
      setState(() => _error = _copy.passwordMismatch);
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      final api = ref.read(radioudaanApiProvider);
      final pending = await api.register(
        name: name,
        email: email,
        phoneE164: phone,
        password: password,
      );

      if (!pending.needsPhoneVerification) {
        setState(() => _error = _copy.registrationIncomplete);
        return;
      }

      final otp = await api.requestOtp(
        pending.phoneE164,
        purpose: OtpPurpose.verifyPhone,
      );

      if (!mounted) return;
      context.go(
        '/otp',
        extra: OtpRouteArgs(
          requestId: otp.requestId,
          phoneE164: pending.phoneE164,
          resendAfterSec: otp.resendAfterSec,
          devOtp: otp.devOtp,
          purpose: OtpPurpose.verifyPhone,
        ),
      );
    } catch (e) {
      final message = parseApiError(e).message;
      setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = ref.watch(appCopyProvider);
    final branding = ref.watch(appBrandingProvider);
    final passwordHint = _copy.passwordMinHint(_passwordMinLength);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              const SizedBox(height: 12),
              const Center(child: UdaanAuthCompactLogo()),
              const SizedBox(height: 20),
              Semantics(
                header: true,
                label: _copy.registerTitle,
                child: ExcludeSemantics(
                  child: Text(
                    _copy.registerTitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: context.udaan.onBackground,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _copy.registerIntro,
                textAlign: TextAlign.center,
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.udaan.primaryGlow,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              UdaanLabeledField(
                label: _copy.nameLabel,
                controller: _nameController,
                hint: _copy.registerNameHint,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.person_outline,
                autofillHints: const [AutofillHints.name],
                required: true,
              ),
              const SizedBox(height: 18),
              UdaanLabeledField(
                label: _copy.emailLabel,
                controller: _emailController,
                hint: _copy.emailHint,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.mail_outline,
                autofillHints: const [AutofillHints.email],
                required: true,
              ),
              const SizedBox(height: 18),
              UdaanPhoneField(
                copy: copy,
                controller: _phoneInput,
                nationalHint: _copy.registerMobileHint,
                textInputAction: TextInputAction.next,
                required: true,
              ),
              const SizedBox(height: 18),
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
              const SizedBox(height: 18),
              UdaanLabeledField(
                label: _copy.confirmPasswordLabel,
                controller: _confirmController,
                hint: _copy.registerConfirmHint,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                prefixIcon: Icons.shield_outlined,
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
                  child: ExcludeSemantics(
                    child: Text(                    _error!,
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
              const SizedBox(height: 28),
              UdaanPrimaryButton(
                label: _copy.registerButton,
                icon: Icons.arrow_forward_rounded,
                loading: _loading,
                onPressed: _loading ? null : _submit,
              ),
              const SizedBox(height: 20),
              UdaanSignInPrompt(
                copy: copy,
                onSignIn: _loading ? null : () => context.go('/login'),
              ),
              const SizedBox(height: 24),
              UdaanAccessibilityAssistCard(
                copy: copy,
                ),
              const SizedBox(height: 16),
              Text(
                _copy.registerCopyright,
                textAlign: TextAlign.center,
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 12,
                  color: context.udaan.onSurfaceMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
