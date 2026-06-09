import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/network/dio_exception_mapper.dart';
import '../../core/providers/app_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/udaan_colors.dart';
import 'auth_session_helper.dart';
import 'auth_validators.dart';
import 'widgets/udaan_auth_widgets.dart';

/// Email + password sign-in (verified email required by API).
class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
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

  Future<void> _submit() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (!isValidEmail(email)) {
      setState(() => _error = AppStrings.emailInvalid);
      _announce(AppStrings.emailInvalid);
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
            identifier: email,
            password: password,
          );
      await persistAuthSession(ref, session);
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      final apiError = parseApiError(e);
      if (apiError.code == 'email_verification_required' ||
          apiError.code == 'email_not_verified') {
        if (!mounted) return;
        context.go(
          '/verify-email',
          extra: VerifyEmailRouteArgs(email: email),
        );
        return;
      }
      final message = apiError.message;
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
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UdaanAuthTopBar(
                title: branding.appName,
                onBack: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/login');
                  }
                },
              ),
              const SizedBox(height: 16),
              UdaanAuthLogoHeader(
                branding: branding,
                subtitle: AppStrings.loginEmailIntro,
              ),
              const SizedBox(height: 32),
              UdaanLabeledField(
                label: AppStrings.emailLabel,
                controller: _emailController,
                hint: AppStrings.emailHint,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.mail_outline,
                autofillHints: const [AutofillHints.email, AutofillHints.username],
                required: true,
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.loginEmailVerifiedNote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: UdaanColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
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
                  onPressed:
                      _loading ? null : () => context.push('/forgot-password'),
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
                onPressed: _loading ? null : _submit,
              ),
              const SizedBox(height: 16),
              UdaanOutlineButton(
                label: AppStrings.signInWithMobile,
                icon: Icons.smartphone_outlined,
                onPressed: _loading ? null : () => context.go('/login'),
              ),
              const SizedBox(height: 32),
              UdaanAuthFooterPrompt(
                prompt: AppStrings.dontHaveAccount,
                actionLabel: AppStrings.registerHere,
                onAction: _loading ? null : () => context.push('/register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
