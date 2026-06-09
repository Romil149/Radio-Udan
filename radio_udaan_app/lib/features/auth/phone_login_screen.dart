import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/providers/app_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/udaan_colors.dart';
import 'auth_otp_flow.dart';
import 'widgets/udaan_auth_widgets.dart';
import 'widgets/udaan_phone_field.dart';

/// Collects mobile number and starts OTP sign-in (Stitch Udaan Core).
class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({this.args, super.key});

  final PhoneLoginRouteArgs? args;

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _phoneInput = PhoneCountryInputController();
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final prefill = widget.args?.initialPhoneInput ?? '';
    if (prefill.isNotEmpty) {
      _phoneInput.setFromRawInput(prefill);
    }
  }

  @override
  void dispose() {
    _phoneInput.dispose();
    super.dispose();
  }

  void _announceError(String message) {
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
    final phone = _phoneInput.e164;
    if (phone == null) {
      setState(() => _error = AppStrings.phoneInvalid);
      _announceError(AppStrings.phoneInvalid);
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    final message = await requestLoginOtpAndOpenVerify(context, ref, phone);
    if (!mounted) return;
    if (message != null) {
      setState(() => _error = message);
      _announceError(message);
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(appBrandingProvider);
    final copy = ref.watch(appCopyProvider);

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
                subtitle: copy.signInIntro,
              ),
              const SizedBox(height: 32),
              UdaanPhoneField(
                controller: _phoneInput,
                textInputAction: TextInputAction.done,
                required: true,
                onSubmitted: (_) {
                  if (!_loading) _submit();
                },
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
              const SizedBox(height: 32),
              UdaanPrimaryButton(
                label: AppStrings.otpSendCode,
                icon: Icons.sms_outlined,
                loading: _loading,
                onPressed: _loading ? null : _submit,
              ),
              const SizedBox(height: 16),
              UdaanOutlineButton(
                label: AppStrings.signInWithPassword,
                icon: Icons.lock_outline,
                onPressed: _loading ? null : () => context.go('/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
