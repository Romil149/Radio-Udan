import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_strings.dart';
import '../../core/network/dio_exception_mapper.dart';
import '../../core/providers/app_providers.dart';
import '../../core/router/event_deep_link.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/udaan_colors.dart';
import 'auth_session_helper.dart';
import 'widgets/udaan_auth_widgets.dart';
import 'widgets/udaan_otp_pin_row.dart';

/// Confirms email ownership with a 6-digit verification code (authenticated).
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({this.args, super.key});

  final VerifyEmailRouteArgs? args;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  late final TextEditingController _emailController;
  final _codeController = TextEditingController();
  String? _error;
  bool _loading = false;
  bool _resending = false;
  int _resendSecondsRemaining = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    final fromArgs = widget.args?.email ?? '';
    final fromUser = ref.read(authUserProvider)?.email ?? '';
    _emailController = TextEditingController(
      text: fromArgs.isNotEmpty ? fromArgs : fromUser,
    );
    _startResendCountdown(60);
    _prefillEmailFromStorage();
  }

  Future<void> _prefillEmailFromStorage() async {
    if (_emailController.text.isNotEmpty) return;
    final email = await ref.read(tokenStorageProvider).readEmail();
    if (email != null && email.isNotEmpty && mounted) {
      _emailController.text = email;
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _startResendCountdown(int seconds) {
    _resendTimer?.cancel();
    _resendSecondsRemaining = seconds;
    if (seconds <= 0) return;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_resendSecondsRemaining <= 1) {
        _resendTimer?.cancel();
        setState(() => _resendSecondsRemaining = 0);
      } else {
        setState(() => _resendSecondsRemaining -= 1);
      }
    });
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

  bool get _canResend =>
      !_loading && !_resending && _resendSecondsRemaining <= 0;

  bool get _emailReadOnly {
    final fromArgs = widget.args?.email ?? '';
    final userEmail = ref.read(authUserProvider)?.email ?? '';
    return fromArgs.isNotEmpty || userEmail.isNotEmpty;
  }

  Future<void> _resend() async {
    setState(() {
      _error = null;
      _resending = true;
    });

    try {
      await ref.read(radioudaanApiProvider).resendVerificationEmail();
      _startResendCountdown(60);
      _announce(AppStrings.verificationCodeResent);
    } catch (e) {
      final message = parseApiError(e).message;
      setState(() => _error = message);
      _announce(message);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();

    if (code.length != 6) {
      setState(() => _error = AppStrings.verificationCodeRequired);
      _announce(AppStrings.verificationCodeRequired);
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      final session = await ref.read(radioudaanApiProvider).verifyEmail(
            code: code,
          );
      await persistAuthSession(ref, session);
      if (!mounted) return;
      navigateAfterAuth(context, ref);
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
    final branding = ref.watch(appBrandingProvider);
    final email = _emailController.text.trim();

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
                    context.go('/');
                  }
                },
              ),
              const Divider(
                height: 24,
                thickness: 1,
                color: UdaanColors.outlineVariant,
              ),
              const SizedBox(height: 8),
              const Center(child: UdaanOtpHeroIcon()),
              const SizedBox(height: 28),
              Semantics(
                header: true,
                label: AppStrings.verifyEmailTitle,
                child: Text(
                  AppStrings.verifyEmailTitle,
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
                AppStrings.verifyEmailIntro,
                textAlign: TextAlign.center,
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: UdaanColors.primaryGlow,
                  height: 1.35,
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  AppStrings.verifyEmailSentTo(email),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: UdaanColors.onBackground.withValues(alpha: 0.9),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              UdaanLabeledField(
                label: AppStrings.emailLabel,
                controller: _emailController,
                hint: _emailReadOnly
                    ? AppStrings.profileEmailLockedHint
                    : AppStrings.emailHint,
                keyboardType: TextInputType.emailAddress,
                readOnly: _emailReadOnly,
                prefixIcon: Icons.mail_outline,
                semanticsLabel: _emailReadOnly && email.isNotEmpty
                    ? AppStrings.profileEmailSemantics(email)
                    : null,
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.verificationCodeLabel,
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: UdaanColors.onBackground,
                ),
              ),
              const SizedBox(height: 8),
              UdaanOtpPinRow(
                controller: _codeController,
                length: 6,
                enabled: !_loading && !_resending,
                semanticsHint: AppStrings.otpPinRowEmailHint(6),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: UdaanAuthLink(
                  label: _resending
                      ? AppStrings.resendingCodePleaseWait
                      : _resendSecondsRemaining > 0
                          ? AppStrings.resendInSeconds(_resendSecondsRemaining)
                          : AppStrings.resendCode,
                  onPressed: _canResend ? _resend : null,
                ),
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
                label: AppStrings.verifyAndContinue,
                icon: Icons.verified_outlined,
                loading: _loading,
                onPressed: _loading || _resending ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
