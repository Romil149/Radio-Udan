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

enum _ForgotChannel { email, phone }

/// Requests password reset by email or mobile (Stitch forgot password screen).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  AppCopy get _copy => ref.read(appCopyProvider);

  _ForgotChannel _channel = _ForgotChannel.email;
  final _emailController = TextEditingController();
  final _phoneInput = PhoneCountryInputController();
  String? _error;
  String? _success;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneInput.dispose();
    super.dispose();
  }

  void _setChannel(_ForgotChannel channel) {
    if (_channel == channel) return;
    setState(() {
      _channel = channel;
      _error = null;
      _success = null;
    });
  }

  Future<void> _submit() async {
    final String identifier;
    if (_channel == _ForgotChannel.email) {
      final email = _emailController.text.trim().toLowerCase();
      if (!isValidEmail(email)) {
        setState(() {
          _error = _copy.emailInvalid;
          _success = null;
        });
        return;
      }
      identifier = email;
    } else {
      final phone = _phoneInput.e164;
      if (phone == null) {
        setState(() {
          _error = _copy.phoneInvalid;
          _success = null;
        });
        return;
      }
      identifier = phone;
    }

    setState(() {
      _error = null;
      _success = null;
      _loading = true;
    });

    try {
      final data = await ref.read(radioudaanApiProvider).forgotPassword(
            identifier: identifier,
          );

      // SMS reset returns request_id (OTP service does not echo phone_e164).
      final requestId = data['request_id']?.toString();
      if (requestId != null && requestId.isNotEmpty) {
        final phoneFromApi = data['phone_e164']?.toString().trim() ?? '';
        final phoneE164 = phoneFromApi.isNotEmpty ? phoneFromApi : identifier;
        if (!mounted) return;
        context.push(
          '/otp',
          extra: OtpRouteArgs(
            requestId: requestId,
            phoneE164: phoneE164,
            resendAfterSec: (data['resend_after_sec'] as num?)?.toInt() ?? 60,
            devOtp: data['dev_otp']?.toString(),
            purpose: OtpPurpose.resetPassword,
          ),
        );
        return;
      }

      setState(() => _success = _copy.forgotPasswordSuccess);
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
    final isEmail = _channel == _ForgotChannel.email;

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
                trailing: Semantics(
                  label: _copy.accountIcon,
                  child: Icon(
                    Icons.person_outline,
                    color: UdaanColors.primaryGlow.withValues(alpha: 0.95),
                    size: 26,
                  ),
                ),
              ),
              const Divider(
                height: 24,
                thickness: 1,
                color: UdaanColors.outlineVariant,
              ),
              const SizedBox(height: 8),
              Center(child: UdaanForgotPasswordHero(
                copy: copy,
                )),
              const SizedBox(height: 28),
              Semantics(
                header: true,
                label: _copy.forgotPasswordTitle,
                child: Text(
                  _copy.forgotPasswordTitle,
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
                _copy.forgotPasswordIntro,
                textAlign: TextAlign.center,
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: UdaanColors.primaryGlow,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 28),
              Semantics(
                label: _copy.forgotPasswordChannelSemantics,
                child: Row(
                  children: [
                    Expanded(
                      child: _ForgotChannelChip(
                        label: _copy.forgotPasswordChannelEmail,
                        selected: isEmail,
                        onTap: () => _setChannel(_ForgotChannel.email),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ForgotChannelChip(
                        label: _copy.forgotPasswordChannelPhone,
                        selected: !isEmail,
                        onTap: () => _setChannel(_ForgotChannel.phone),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (isEmail) ...[
                UdaanLabeledField(
                  label: _copy.emailLabel,
                  controller: _emailController,
                  hint: _copy.forgotPasswordEmailHint,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icons.mail_outline,
                  autofillHints: const [AutofillHints.email],
                  required: true,
                  onSubmitted: (_) => _loading ? null : _submit(),
                ),
                const SizedBox(height: 8),
                Text(
                  _copy.forgotPasswordEmailNote,
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 14,
                    color: UdaanColors.onSurfaceVariant.withValues(alpha: 0.9),
                  ),
                ),
              ] else ...[
                UdaanPhoneField(
                copy: copy,
                controller: _phoneInput,
                  textInputAction: TextInputAction.done,
                  required: true,
                  onSubmitted: (_) {
                    if (!_loading) _submit();
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  _copy.forgotPasswordPhoneNote,
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 14,
                    color: UdaanColors.onSurfaceVariant.withValues(alpha: 0.9),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  label: _error,
                  liveRegion: true,
                  child: ExcludeSemantics(
                    child: Text(                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: UdaanColors.error,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    ),
                  ),
                ),
              ],
              if (_success != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  label: _success,
                  liveRegion: true,
                  child: ExcludeSemantics(
                    child: Text(                    _success!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: UdaanColors.secondary,
                    ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              UdaanPrimaryButton(
                label: _copy.resetPasswordButton,
                icon: Icons.arrow_forward_rounded,
                loading: _loading,
                onPressed: _loading ? null : _submit,
              ),
              const SizedBox(height: 20),
              Semantics(
                button: true,
                label: _copy.backToLogin,
                child: TextButton.icon(
                  onPressed: _loading ? null : () => context.go('/login'),
                  icon: const Icon(
                    Icons.chevron_left,
                    color: UdaanColors.secondary,
                  ),
                  label: Text(
                    _copy.backToLogin,
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: UdaanColors.secondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              UdaanForgotPasswordHelpCard(
                copy: copy,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ForgotChannelChip extends StatelessWidget {
  const _ForgotChannelChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? UdaanColors.primary : UdaanColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? UdaanColors.primary
                    : UdaanColors.primaryGlow,
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: selected
                    ? UdaanColors.onPrimary
                    : UdaanColors.onBackground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
