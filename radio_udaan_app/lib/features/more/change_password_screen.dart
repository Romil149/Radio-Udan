import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/network/dio_exception_mapper.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/udaan_colors.dart';
import '../auth/auth_session_helper.dart';
import '../auth/widgets/udaan_auth_widgets.dart';
import '../events/widgets/registration_form_styles.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  AppCopy get _copy => ref.read(appCopyProvider);

  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  int get _minLength =>
      ref.read(remoteConfigProvider)?.authPolicy.passwordMinLength ?? 8;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _hasMinLength => _newController.text.length >= _minLength;
  bool get _hasNumber => RegExp(r'\d').hasMatch(_newController.text);
  bool get _hasSpecial =>
      RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/]').hasMatch(_newController.text);
  bool get _passwordsMatch =>
      _newController.text.isNotEmpty &&
      _newController.text == _confirmController.text;

  Future<void> _submit() async {
    if (!_hasMinLength || !_passwordsMatch) {
      setState(() => _error = _copy.passwordRequirementsNotMet);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(radioudaanApiProvider).changePassword(
            currentPassword: _currentController.text,
            newPassword: _newController.text,
          );
      await clearAuthSession(ref);
      if (!mounted) return;
      SemanticsService.sendAnnouncement(
        View.of(context),
        _copy.passwordChangedSignInAgain,
        Directionality.of(context),
      );
      context.go('/login');
    } catch (e) {
      final message = parseApiError(e).message;
      setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _passwordField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: Text(
              label,
              style: registrationFieldLabelStyle(context, required: true),
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: label,
            textField: true,
            obscured: obscure,
            child: ExcludeSemantics(
              child: TextField(
              controller: controller,
              obscureText: obscure,
              onChanged: (_) => setState(() {}),
              style: registrationFieldInputStyle(context),
              decoration: registrationFieldDecoration(
                context,
                suffixIcon: Semantics(
                  button: true,
                  label: obscure
                      ? _copy.showPassword
                      : _copy.hidePassword,
                  child: ExcludeSemantics(
                    child: IconButton(
                      onPressed: onToggle,
                      icon: Icon(
                        obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: context.udaan.primaryGlow,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _requirement(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Semantics(
        label: met
            ? _copy.passwordRequirementMet(text)
            : _copy.passwordRequirementNotMet(text),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(
                met ? Icons.check_circle : Icons.circle_outlined,
                color:
                    met ? context.udaan.secondary : context.udaan.onSurfaceVariant,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ExcludeSemantics(
                child: Text(
                  text,
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 15,
                    color: context.udaan.onBackground,
                  ),
                ),
              ),
            ),
          ],
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BrandTokens.screenPadding,
              ),
              child: UdaanAuthTopBar(
                copy: copy,
                title: branding.appName,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(BrandTokens.screenPadding),
                children: [
                  Semantics(
                    header: true,
                    child: ExcludeSemantics(
                      child: Text(
                        _copy.changePasswordTitle,
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: context.udaan.onBackground,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _copy.changePasswordIntro,
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 16,
                      color: context.udaan.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _passwordField(
                    context: context,
                    label: _copy.currentPassword,
                    controller: _currentController,
                    obscure: _obscureCurrent,
                    onToggle: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                  _passwordField(
                    context: context,
                    label: _copy.newPassword,
                    controller: _newController,
                    obscure: _obscureNew,
                    onToggle: () =>
                        setState(() => _obscureNew = !_obscureNew),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.udaan.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _requirement('$_minLength+ Characters', _hasMinLength),
                        _requirement('Includes a Number', _hasNumber),
                        _requirement('Special Character', _hasSpecial),
                        _requirement('Passwords Match', _passwordsMatch),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _passwordField(
                    context: context,
                    label: _copy.confirmNewPassword,
                    controller: _confirmController,
                    obscure: _obscureConfirm,
                    onToggle: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  if (_error != null)
                    Semantics(
                      label: _error,
                      liveRegion: true,
                      child: ExcludeSemantics(
                        child: Text(                        _error!,
                        style: GoogleFonts.atkinsonHyperlegible(
                          color: context.udaan.error,
                        ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  UdaanPrimaryButton(
                    label: _copy.saveNewPassword,
                    icon: Icons.lock_outline,
                    loading: _loading,
                    onPressed: _loading ? null : _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
