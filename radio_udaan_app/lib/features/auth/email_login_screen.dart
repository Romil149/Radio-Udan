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
  AppCopy get _copy => ref.read(appCopyProvider);

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

  void _setError(String message) {
    setState(() => _error = message);
    announceValidationError(context, message);
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (!isValidEmail(email)) {
      _setError(_copy.emailInvalid);
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
            identifier: email,
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
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UdaanAuthTopBar(
                copy: copy,
                title: _copy.signInWithEmail,
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
                subtitle: _copy.loginEmailIntro,
                showAppNameHeader: false,
              ),
              const SizedBox(height: 32),
              UdaanLabeledField(
                label: _copy.emailLabel,
                controller: _emailController,
                hint: _copy.emailHint,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.mail_outline,
                autofillHints: const [AutofillHints.email, AutofillHints.username],
                required: true,
              ),
              const SizedBox(height: 8),
              Text(
                _copy.loginEmailVerifiedNote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.udaan.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
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
                  onPressed:
                      _loading ? null : () => context.push('/forgot-password'),
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
                onPressed: _loading ? null : _submit,
              ),
              const SizedBox(height: 16),
              UdaanOutlineButton(
                label: _copy.signInWithMobile,
                icon: Icons.smartphone_outlined,
                onPressed: _loading ? null : () => context.go('/login'),
              ),
              const SizedBox(height: 32),
              UdaanAuthFooterPrompt(
                prompt: _copy.dontHaveAccount,
                actionLabel: _copy.registerHere,
                onAction: _loading ? null : () => context.push('/register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
