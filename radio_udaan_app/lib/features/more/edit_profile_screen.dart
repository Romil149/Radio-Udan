import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/accessibility/udaan_semantics.dart';
import '../../core/network/dio_exception_mapper.dart';
import '../../core/providers/app_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/udaan_colors.dart';
import '../auth/auth_session_helper.dart';
import '../auth/widgets/udaan_auth_widgets.dart';
import '../events/registration_account_prefill.dart';
import '../events/widgets/registration_form_styles.dart';
import 'change_password_screen.dart';
import 'settings_screen.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  AppCopy get _copy => ref.read(appCopyProvider);

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  bool _loading = false;
  String? _error;
  String? _localAvatarPath;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authUserProvider);
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(
      text: formatPhoneForDisplay(user?.phoneE164 ?? ''),
    );
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
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

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() => _localAvatarPath = picked.path);
    setState(() => _loading = true);
    try {
      final session = await ref.read(radioudaanApiProvider).uploadAvatar(
            filePath: picked.path,
            fileName: picked.name,
          );
      await persistAuthSession(ref, session);
      _announce(_copy.profileUpdated);
    } catch (e) {
      _setError(parseApiError(e).message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setError(String message) {
    setState(() => _error = message);
    announceValidationError(context, message);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();

    if (name.length < 2) {
      _setError(_copy.nameRequired);
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      _setError(_copy.emailInvalid);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ref.read(radioudaanApiProvider).updateProfile(
            name: name,
            email: email,
          );
      await persistAuthSession(ref, result.session);

      if (!mounted) return;

      if (result.emailVerificationSent) {
        _announce(_copy.profileEmailVerificationSent);
        Navigator.of(context).pop();
        context.push(
          '/verify-email',
          extra: VerifyEmailRouteArgs(email: email),
        );
        return;
      }

      _announce(_copy.profileUpdated);
      Navigator.of(context).pop();
    } catch (e) {
      _setError(parseApiError(e).message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = ref.watch(appCopyProvider);
    final user = ref.watch(authUserProvider);
    final avatarUrl = user?.avatarUrl;

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
                title: _copy.editProfileTitle,
                onBack: () => Navigator.of(context).pop(),
                trailing: Semantics(
                  button: true,
                  label: _copy.settingsTitle,
                  child: ExcludeSemantics(
                    child: IconButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SettingsScreen(),
                        ),
                      ),
                      icon: Icon(
                        Icons.settings_outlined,
                        color: context.udaan.onBackground,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(BrandTokens.screenPadding),
                children: [
                  Center(
                    child: Semantics(
                      button: true,
                      enabled: !_loading,
                      label: _copy.tapToUpdatePhoto,
                      child: GestureDetector(
                        onTap: _loading ? null : _pickPhoto,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 56,
                              backgroundColor: context.udaan.surfaceContainer,
                              backgroundImage: _localAvatarPath != null
                                  ? FileImage(File(_localAvatarPath!))
                                  : (avatarUrl != null && avatarUrl.isNotEmpty
                                      ? CachedNetworkImageProvider(avatarUrl)
                                      : null),
                              child: avatarUrl == null && _localAvatarPath == null
                                  ? Icon(Icons.person, size: 48)
                                  : null,
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: context.udaan.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: context.udaan.onPrimary,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: ExcludeSemantics(
                      child: Text(
                        _copy.tapToUpdatePhoto,
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 14,
                          color: context.udaan.primaryGlow,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _labeledField(
                    context: context,
                    label: _copy.nameLabel,
                    controller: _nameController,
                  ),
                  _labeledField(
                    context: context,
                    label: _copy.mobileNumberLabel,
                    controller: _phoneController,
                    readOnly: true,
                    semanticsLabel: _copy.profileMobileSemantics(
                      _phoneController.text,
                    ),
                    hint: _copy.profileMobileLockedHint,
                    suffixIcon: Icon(
                      Icons.lock_outline,
                      color: context.udaan.onSurfaceVariant,
                    ),
                  ),
                  _labeledField(
                    context: context,
                    label: _copy.emailLabel,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.udaan.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border(
                        left: BorderSide(color: context.udaan.primaryGlow, width: 3),
                      ),
                    ),
                    child: Text(
                      _copy.profileInfoNote,
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 15,
                        color: context.udaan.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    button: true,
                    label: _copy.changePasswordTitle,
                    child: ExcludeSemantics(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ChangePasswordScreen(),
                          ),
                        ),
                        child: Text(
                          _copy.changePasswordTitle,
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: context.udaan.primaryGlow,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
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
                  ],
                  const SizedBox(height: 20),
                  UdaanPrimaryButton(
                    label: _copy.updateProfile,
                    icon: Icons.check_circle_outline,
                    loading: _loading,
                    onPressed: _loading ? null : _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _labeledField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool readOnly = false,
    String? semanticsLabel,
    String? hint,
    Widget? suffixIcon,
  }) {
    final field = TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      enableInteractiveSelection: !readOnly,
      style: registrationFieldInputStyle(context, readOnly: readOnly),
      decoration: registrationFieldDecoration(context).copyWith(
        suffixIcon: suffixIcon,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: Text(
              label,
              style: registrationFieldLabelStyle(context),
            ),
          ),
          if (hint != null && hint.isNotEmpty) ...[
            const SizedBox(height: 4),
            ExcludeSemantics(
              child: Text(
                hint,
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 14,
                  color: context.udaan.onSurfaceVariant,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (readOnly && semanticsLabel != null)
            Semantics(
              label: semanticsLabel,
              readOnly: true,
              textField: true,
              child: ExcludeSemantics(child: field),
            )
          else
            Semantics(
              textField: true,
              label: '$label, required',
              child: ExcludeSemantics(child: field),
            ),
        ],
      ),
    );
  }
}
