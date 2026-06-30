import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
  AppCopy get _copy => ref.read(appCopyProvider);

  late final TextEditingController _emailController;
  final _codeController = TextEditingController();
  String? _error;
  bool _loading = false;
  bool _resending = false;
  bool _initialSendDone = false;
  int _resendSecondsRemaining = 0;
  Timer? _resendTimer;

  static const int _resendCooldownSec = 60;

  @override
  void initState() {
    super.initState();
    final fromArgs = widget.args?.email ?? '';
    final fromUser = ref.read(authUserProvider)?.email ?? '';
    _emailController = TextEditingController(
      text: fromArgs.isNotEmpty ? fromArgs : fromUser,
    );
    _prefillEmailFromStorage();
    if (widget.args?.sendCodeOnOpen ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _sendInitialCode();
      });
    }
  }

  Future<void> _sendInitialCode() async {
    if (_initialSendDone) return;
    final token = ref.read(authTokenProvider);
    if (token == null || token.isEmpty) return;
    final user = ref.read(authUserProvider);
    if (user?.emailVerified == true) return;
    _initialSendDone = true;
    await _resend(announceOnSuccess: false);
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

  Future<void> _resend({bool announceOnSuccess = true}) async {
    setState(() {
      _error = null;
      _resending = true;
    });

    try {
      await ref.read(radioudaanApiProvider).resendVerificationEmail();
      _startResendCountdown(_resendCooldownSec);
      if (announceOnSuccess) {
        _announce(_copy.verificationCodeResent);
      }
    } catch (e) {
      final message = parseApiError(e).message;
      setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();

    if (code.length != 6) {
      setState(() => _error = _copy.verificationCodeRequired);
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
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = ref.watch(appCopyProvider);
    final email = _emailController.text.trim();

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
                title: _copy.verifyEmailTitle,
                onBack: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
              ),
              Divider(
                height: 24,
                thickness: 1,
                color: context.udaan.outlineVariant,
              ),
              const SizedBox(height: 8),
              Center(child: UdaanOtpHeroIcon(
                copy: copy,
                )),
              const SizedBox(height: 28),
              Semantics(
                header: true,
                label: _copy.verifyEmailTitle,
                child: ExcludeSemantics(
                  child: Text(
                    _copy.verifyEmailTitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: context.udaan.onBackground,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _copy.verifyEmailIntro,
                textAlign: TextAlign.center,
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: context.udaan.primaryGlow,
                  height: 1.35,
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 8),
                ExcludeSemantics(
                  child: Text(
                    _copy.verifyEmailSentTo(email),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.udaan.onBackground.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              UdaanLabeledField(
                label: _copy.emailLabel,
                controller: _emailController,
                hint: _emailReadOnly
                    ? _copy.profileEmailLockedHint
                    : _copy.emailHint,
                keyboardType: TextInputType.emailAddress,
                readOnly: _emailReadOnly,
                prefixIcon: Icons.mail_outline,
                semanticsLabel: _emailReadOnly && email.isNotEmpty
                    ? _copy.profileEmailSemantics(email)
                    : null,
              ),
              const SizedBox(height: 24),
              ExcludeSemantics(
                child: Text(
                  _copy.verificationCodeLabel,
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.udaan.onBackground,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              UdaanOtpPinRow(
                copy: copy,
                controller: _codeController,
                length: 6,
                enabled: !_loading && !_resending,
                semanticsHint: _copy.otpPinRowEmailHint(6),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: UdaanAuthLink(
                  label: _resending
                      ? _copy.resendingCodePleaseWait
                      : _resendSecondsRemaining > 0
                          ? _copy.resendInSeconds(_resendSecondsRemaining)
                          : _copy.resendCode,
                  onPressed: _canResend ? () => _resend() : null,
                ),
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
                label: _copy.verifyAndContinue,
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
