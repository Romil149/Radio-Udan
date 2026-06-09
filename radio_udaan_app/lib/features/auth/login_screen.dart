import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/network/dio_exception_mapper.dart';
import '../../core/providers/app_providers.dart';
import '../../core/router/app_router.dart';
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

  Future<void> _startOtpLogin() async {
    final phone = _phoneInput.e164;
    if (phone == null) {
      setState(() => _error = AppStrings.phoneInvalid);
      _announce(AppStrings.phoneInvalid);
      return;
    }

    setState(() {
      _error = null;
      _otpLoading = true;
    });

    final message = await requestLoginOtpAndOpenVerify(context, ref, phone);
    if (!mounted) return;
    if (message != null) {
      setState(() => _error = message);
      _announce(message);
    }
    setState(() => _otpLoading = false);
  }

  Future<void> _submit() async {
    final phone = _phoneInput.e164;
    final password = _passwordController.text;

    if (phone == null) {
      setState(() => _error = AppStrings.phoneInvalid);
      _announce(AppStrings.phoneInvalid);
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = AppStrings.passwordRequired);
      _announce(AppStrings.passwordRequired);
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
        context.go('/');
      }
    } catch (e) {
      final message = parseApiError(e).message;
      setState(() => _error = message);
      _announce(message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _passwordVisibilityToggle() {
    return Semantics(
      button: true,
      label: _obscurePassword ? AppStrings.showPassword : AppStrings.hidePassword,
      child: IconButton(
        icon: Icon(
          _obscurePassword
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: UdaanColors.primaryGlow,
        ),
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(appBrandingProvider);

    return Scaffold(
      backgroundColor: UdaanColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UdaanAuthLogoHeader(
                branding: branding,
                subtitle: AppStrings.loginMobileIntro,
              ),
              const SizedBox(height: 32),
              UdaanPhoneField(
                controller: _phoneInput,
                textInputAction: TextInputAction.next,
                required: true,
              ),
              const SizedBox(height: 20),
              UdaanLabeledField(
                label: AppStrings.passwordLabel,
                controller: _passwordController,
                hint: AppStrings.loginPasswordHint,
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
                  label: AppStrings.forgotPasswordLink,
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
                  child: Text(
                    _error!,
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
                label: AppStrings.loginButton,
                icon: Icons.login_rounded,
                loading: _loading,
                onPressed: _loading || _otpLoading ? null : _submit,
              ),
              const SizedBox(height: 16),
              UdaanOutlineButton(
                label: AppStrings.signInWithOtp,
                icon: Icons.sms_outlined,
                loading: _otpLoading,
                onPressed: _loading || _otpLoading ? null : _startOtpLogin,
              ),
              const SizedBox(height: 16),
              UdaanOutlineButton(
                label: AppStrings.signInWithEmail,
                icon: Icons.mail_outline,
                onPressed: _loading || _otpLoading
                    ? null
                    : () => context.push('/login-email'),
              ),
              const SizedBox(height: 32),
              UdaanAuthFooterPrompt(
                prompt: AppStrings.dontHaveAccount,
                actionLabel: AppStrings.registerHere,
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
