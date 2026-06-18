import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/models/otp_purpose.dart';
import '../../core/network/dio_exception_mapper.dart';
import '../../core/providers/app_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/router/event_deep_link.dart';
import '../../core/theme/udaan_colors.dart';
import '../more/help_contact_screen.dart';
import 'auth_session_helper.dart';
import 'widgets/otp_verify_identity_body.dart';
import 'widgets/otp_verify_login_body.dart';

/// Verifies SMS OTP — login or registration (`OtpPurpose`).
class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({this.args, super.key});

  final OtpRouteArgs? args;

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final _otpController = TextEditingController();
  String? _error;
  bool _loading = false;
  bool _resending = false;
  bool _bootstrapping = false;
  late String _requestId;
  late String _phoneE164;
  late OtpPurpose _purpose;
  int _resendSecondsRemaining = 0;
  String? _devOtp;
  Timer? _resendTimer;

  bool get _isIdentityVerify => _purpose == OtpPurpose.verifyPhone;

  int _initialResendDelaySec() {
    final fromArgs = widget.args?.resendAfterSec;
    if (fromArgs != null && fromArgs > 0) {
      return fromArgs;
    }
    return ref.read(remoteConfigProvider)?.otpResendDelaySec ?? 60;
  }

  @override
  void initState() {
    super.initState();
    _requestId = widget.args?.requestId ?? '';
    _phoneE164 = widget.args?.phoneE164 ?? '';
    _purpose = widget.args?.purpose ?? OtpPurpose.login;
    _devOtp = widget.args?.devOtp;
    _resendSecondsRemaining = _initialResendDelaySec();
    _startResendCountdown();
    if (kDebugMode) {
      final dev = _devOtp;
      if (dev != null && dev.isNotEmpty) {
        _otpController.text = dev;
      }
    }
    if (widget.args == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapMissingArgs());
    }
  }

  Future<void> _bootstrapMissingArgs() async {
    final token = ref.read(authTokenProvider);
    final user = ref.read(authUserProvider);
    if (token == null || token.isEmpty || user == null) {
      if (mounted) context.go('/login');
      return;
    }
    if (user.phoneVerified) {
      if (mounted) context.go('/');
      return;
    }
    final phone = user.phoneE164.trim();
    if (phone.isEmpty) {
      if (mounted) context.go('/login');
      return;
    }

    setState(() {
      _bootstrapping = true;
      _error = null;
      _phoneE164 = phone;
      _purpose = OtpPurpose.verifyPhone;
    });

    try {
      final result = await ref.read(radioudaanApiProvider).requestOtp(
            phone,
            purpose: OtpPurpose.verifyPhone,
          );
      if (!mounted) return;
      setState(() {
        _requestId = result.requestId;
        _resendSecondsRemaining = result.resendAfterSec > 0
            ? result.resendAfterSec
            : _initialResendDelaySec();
        if (kDebugMode && result.devOtp != null && result.devOtp!.isNotEmpty) {
          _devOtp = result.devOtp;
          _otpController.text = result.devOtp!;
        }
      });
      _startResendCountdown();
    } catch (e) {
      if (!mounted) return;
      final message = parseApiError(e).message;
      setState(() => _error = message);
      _announce(message);
    } finally {
      if (mounted) setState(() => _bootstrapping = false);
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    if (_resendSecondsRemaining <= 0) {
      return;
    }
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_resendSecondsRemaining <= 1) {
        _resendTimer?.cancel();
        _resendTimer = null;
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

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    if (_isIdentityVerify) {
      context.go('/register');
      return;
    }
    context.go('/otp-login');
  }

  void _openContactSupport() {
    _announce(AppStrings.contactTitle);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const HelpContactScreen(),
      ),
    );
  }

  Future<void> _resend() async {
    final phone = _phoneE164.trim();
    if (phone.isEmpty) {
      if (widget.args == null) {
        await _bootstrapMissingArgs();
        return;
      }
      context.go(_isIdentityVerify ? '/register' : '/login');
      return;
    }
    if (!_canResend) return;

    setState(() {
      _error = null;
      _resending = true;
    });

    try {
      final result = await ref.read(radioudaanApiProvider).requestOtp(
            phone,
            purpose: _purpose,
          );
      if (!mounted) return;
      setState(() {
        _requestId = result.requestId;
        _resendSecondsRemaining = result.resendAfterSec > 0
            ? result.resendAfterSec
            : _initialResendDelaySec();
        _otpController.clear();
        if (kDebugMode && result.devOtp != null && result.devOtp!.isNotEmpty) {
          _devOtp = result.devOtp;
          _otpController.text = result.devOtp!;
        }
      });
      _startResendCountdown();
      _announce(AppStrings.otpResentSuccess);
    } catch (e) {
      final message = parseApiError(e).message;
      setState(() => _error = message);
      _announce(message);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _navigateAfterSession() {
    final user = ref.read(authUserProvider);
    final requireEmail =
        ref.read(remoteConfigProvider)?.authPolicy.requireEmailVerification ??
            false;

    if (requireEmail && user != null && !user.emailVerified) {
      context.go(
        '/verify-email',
        extra: VerifyEmailRouteArgs(email: user.email ?? ''),
      );
      return;
    }
    navigateAfterAuth(context, ref);
  }

  Future<void> _verify() async {
    if (_phoneE164.trim().isEmpty || _requestId.isEmpty) {
      if (widget.args == null) {
        await _bootstrapMissingArgs();
        return;
      }
      context.go('/login');
      return;
    }

    final otp = _otpController.text.trim();
    final otpLength = OtpVerifyIdentityBody.otpLength;
    if (otp.length < otpLength) {
      const message = AppStrings.otpCodeIncomplete;
      setState(() => _error = message);
      _announce(message);
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      final result = await ref.read(radioudaanApiProvider).verifyOtp(
            requestId: _requestId,
            otp: otp,
            purpose: _purpose,
          );

      if (result.resetReady && _purpose == OtpPurpose.resetPassword) {
        if (!mounted) return;
        context.go(
          '/reset-password',
          extra: ResetPasswordRouteArgs(
            phoneE164: result.phoneE164 ?? _phoneE164,
            otp: otp,
          ),
        );
        return;
      }

      final session = result.session;
      if (session == null || !session.hasToken) {
        setState(() => _error = AppStrings.verificationIncomplete);
        _announce(AppStrings.verificationIncomplete);
        return;
      }

      await persistAuthSession(ref, session);
      if (!mounted) return;
      _navigateAfterSession();
    } catch (e) {
      final apiError = parseApiError(e);
      if (apiError.code == 'email_verification_required') {
        final hasToken = (ref.read(authTokenProvider) ?? '').isNotEmpty;
        if (hasToken && mounted) {
          context.go(
            '/verify-email',
            extra: VerifyEmailRouteArgs(
              email: ref.read(authUserProvider)?.email ?? '',
            ),
          );
          return;
        }
        setState(() => _error = apiError.message);
        _announce(apiError.message);
        return;
      }
      final message = apiError.message;
      setState(() => _error = message);
      _announce(message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = _phoneE164;
    final branding = ref.watch(appBrandingProvider);

    if (_bootstrapping) {
      return Scaffold(
        backgroundColor: UdaanColors.background,
        body: Center(
          child: Semantics(
            label: AppStrings.semanticsLoading,
            liveRegion: true,
            child: CircularProgressIndicator(color: UdaanColors.primary),
          ),
        ),
      );
    }

    final body = _isIdentityVerify
        ? OtpVerifyIdentityBody(
            brandingAppName: branding.appName,
            phoneE164: phone,
            otpController: _otpController,
            error: _error,
            loading: _loading,
            resending: _resending,
            canResend: _canResend,
            devOtp: _devOtp,
            onBack: _goBack,
            onVerify: _verify,
            onResend: _resend,
            onContactSupport: _openContactSupport,
          )
        : OtpVerifyLoginBody(
            brandingAppName: branding.appName,
            phoneE164: phone,
            otpController: _otpController,
            error: _error,
            loading: _loading,
            resending: _resending,
            canResend: _canResend,
            resendSecondsRemaining: _resendSecondsRemaining,
            devOtp: _devOtp,
            onBack: _goBack,
            onVerify: _verify,
            onResend: _resend,
          );

    return Scaffold(
      backgroundColor: UdaanColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: body,
        ),
      ),
    );
  }
}
