import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibility/udaan_semantics.dart';
import '../../core/network/dio_exception_mapper.dart';
import '../../core/providers/app_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/router/event_deep_link.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/udaan_colors.dart';
import 'auth_otp_flow.dart';
import 'auth_session_helper.dart';
import 'widgets/udaan_auth_widgets.dart';
import 'widgets/udaan_phone_field.dart';

/// Mobile + password sign-in (primary). OTP and email login are secondary paths.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  AppCopy get _copy => ref.read(appCopyProvider);

  final _phoneInput = PhoneCountryInputController();
  final _passwordController = TextEditingController();
  String? _error;
  bool _loading = false;
  bool _otpLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneInput.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setError(String message) {
    setState(() => _error = message);
    announceValidationError(context, message);
  }

  Future<void> _startOtpLogin() async {
    final phone = _phoneInput.e164;
    if (phone == null) {
      _setError(_copy.phoneInvalid);
      return;
    }

    setState(() {
      _error = null;
      _otpLoading = true;
    });

    final message = await requestLoginOtpAndOpenVerify(context, ref, phone);
    if (!mounted) return;
    if (message != null) {
      _setError(message);
    }
    setState(() => _otpLoading = false);
  }

  Future<void> _submit() async {
    final phone = _phoneInput.e164;
    final password = _passwordController.text;

    if (phone == null) {
      _setError(_copy.phoneInvalid);
      return;
    }
    if (password.isEmpty) {
      _setError(_copy.passwordRequired);
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      final session = await ref.read(radioudaanApiProvider).login(
            identifier: phone,
            password: password,
          );
      await persistAuthSession(ref, session);
      if (!mounted) return;
      final requireEmail = ref
              .read(remoteConfigProvider)
              ?.authPolicy
              .requireEmailVerification ??
          false;
      if (requireEmail && !session.emailVerified) {
        context.go(
          '/verify-email',
          extra: VerifyEmailRouteArgs(email: session.email ?? ''),
        );
      } else {
        navigateAfterAuth(context, ref);
      }
    } catch (e) {
      _setError(parseApiError(e).message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _passwordVisibilityToggle() {
    return Semantics(
      button: true,
      label: _obscurePassword ? _copy.showPassword : _copy.hidePassword,
      child: ExcludeSemantics(
        child: IconButton(
          constraints: const BoxConstraints(
            minWidth: BrandTokens.a11yMinTapTarget,
            minHeight: BrandTokens.a11yMinTapTarget,
          ),
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: context.udaan.primaryGlow,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = ref.watch(appCopyProvider);
    final branding = ref.watch(appBrandingProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UdaanAuthLogoHeader(
                branding: branding,
                subtitle: _copy.loginMobileIntro,
              ),
              const SizedBox(height: 32),
              UdaanPhoneField(
                copy: copy,
                controller: _phoneInput,
                textInputAction: TextInputAction.next,
                required: true,
              ),
              const SizedBox(height: 20),
              UdaanLabeledField(
                label: _copy.passwordLabel,
                controller: _passwordController,
                hint: _copy.loginPasswordHint,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                prefixIcon: Icons.lock_outline,
                autofillHints: const [AutofillHints.password],
                required: true,
                suffixIcon: _passwordVisibilityToggle(),
                onSubmitted: (_) => _loading ? null : _submit(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: UdaanAuthLink(
                  label: _copy.forgotPasswordLink,
                  onPressed: _loading || _otpLoading
                      ? null
                      : () => context.push('/forgot-password'),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  label: _error,
                  liveRegion: true,
                  child: ExcludeSemantics(
                    child: Text(                    _error!,
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
                label: _copy.loginButton,
                icon: Icons.login_rounded,
                loading: _loading,
                onPressed: _loading || _otpLoading ? null : _submit,
              ),
              const SizedBox(height: 16),
              UdaanOutlineButton(
                label: _copy.signInWithOtp,
                icon: Icons.sms_outlined,
                loading: _otpLoading,
                onPressed: _loading || _otpLoading ? null : _startOtpLogin,
              ),
              const SizedBox(height: 16),
              UdaanOutlineButton(
                label: _copy.signInWithEmail,
                icon: Icons.mail_outline,
                onPressed: _loading || _otpLoading
                    ? null
                    : () => context.push('/login-email'),
              ),
              const SizedBox(height: 32),
              UdaanAuthFooterPrompt(
                prompt: _copy.dontHaveAccount,
                actionLabel: _copy.registerHere,
                onAction: _loading || _otpLoading
                    ? null
                    : () => context.push('/register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
