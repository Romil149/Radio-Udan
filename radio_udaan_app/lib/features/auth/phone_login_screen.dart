import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibility/udaan_semantics.dart';
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
  AppCopy get _copy => ref.read(appCopyProvider);

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

  void _setError(String message) {
    setState(() => _error = message);
    announceValidationError(context, message);
  }

  Future<void> _submit() async {
    final phone = _phoneInput.e164;
    if (phone == null) {
      _setError(_copy.phoneInvalid);
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    final message = await requestLoginOtpAndOpenVerify(context, ref, phone);
    if (!mounted) return;
    if (message != null) {
      _setError(message);
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(appBrandingProvider);
    final copy = ref.watch(appCopyProvider);

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
                title: _copy.signInWithMobile,
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
                subtitle: _copy.signInIntro,
                showAppNameHeader: false,
              ),
              const SizedBox(height: 32),
              UdaanPhoneField(
                copy: copy,
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
              const SizedBox(height: 32),
              UdaanPrimaryButton(
                label: _copy.otpSendCode,
                icon: Icons.sms_outlined,
                loading: _loading,
                onPressed: _loading ? null : _submit,
              ),
              const SizedBox(height: 16),
              UdaanOutlineButton(
                label: _copy.signInWithPassword,
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
