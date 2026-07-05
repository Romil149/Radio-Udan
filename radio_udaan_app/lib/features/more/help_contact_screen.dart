import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/accessibility/udaan_semantics.dart';
import '../../core/network/dio_exception_mapper.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/udaan_colors.dart';
import '../../core/utils/keyboard_dismiss.dart';
import '../auth/widgets/udaan_auth_widgets.dart';
import '../events/widgets/registration_form_styles.dart';

/// Contact form for support messages.
class HelpContactScreen extends ConsumerStatefulWidget {
  const HelpContactScreen({super.key});

  @override
  ConsumerState<HelpContactScreen> createState() => _HelpContactScreenState();
}

class _HelpContactScreenState extends ConsumerState<HelpContactScreen> {
  AppCopy get _copy => ref.read(appCopyProvider);

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _subjectController;
  late final TextEditingController _messageController;
  bool _sending = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authUserProvider);
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _subjectController = TextEditingController();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _setError(String message) {
    setState(() => _error = message);
    announceValidationError(context, message);
  }

  void _setSuccess(String message) {
    setState(() => _success = message);
    announce(context, message);
  }

  Future<void> _send() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    if (name.isEmpty) {
      _setError('${_copy.nameLabel}, ${_copy.registrationFieldRequired}');
      return;
    }
    if (email.isEmpty) {
      _setError('${_copy.emailLabel}, ${_copy.registrationFieldRequired}');
      return;
    }
    if (subject.isEmpty) {
      _setError('${_copy.helpSubject}, ${_copy.registrationFieldRequired}');
      return;
    }
    if (message.isEmpty) {
      _setError('${_copy.helpMessage}, ${_copy.registrationFieldRequired}');
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
      _success = null;
    });

    try {
      await ref.read(radioudaanApiProvider).submitSupportContact(
            name: name,
            email: email,
            subject: subject,
            message: message,
          );
      _setSuccess(_copy.messageSent);
      _subjectController.clear();
      _messageController.clear();
    } catch (e) {
      _setError(parseApiError(e).message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                copy: ref.watch(appCopyProvider),
                title: _copy.contactTitle,
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
                        _copy.contactFormTitle,
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: context.udaan.primaryGlow,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _copy.contactFormIntro,
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: context.udaan.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _field(context, _copy.nameLabel, _nameController),
                  _field(
                    context,
                    _copy.emailLabel,
                    _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _field(context, _copy.helpSubject, _subjectController),
                  _field(
                    context,
                    _copy.helpMessage,
                    _messageController,
                    maxLines: 5,
                  ),
                  if (_error != null)
                    Semantics(
                      label: _error,
                      liveRegion: true,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ExcludeSemantics(
                          child: Text(
                            _error!,
                            style: TextStyle(color: context.udaan.error),
                          ),
                        ),
                      ),
                    ),
                  if (_success != null)
                    Semantics(
                      label: _success,
                      liveRegion: true,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ExcludeSemantics(
                          child: Text(
                            _success!,
                            style: TextStyle(color: context.udaan.secondary),
                          ),
                        ),
                      ),
                    ),
                  UdaanPrimaryButton(
                    label: _copy.sendMessage,
                    icon: Icons.send_outlined,
                    loading: _sending,
                    onPressed: _sending ? null : _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    BuildContext context,
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: Text(label, style: registrationFieldLabelStyle(context)),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: '$label, required',
            textField: true,
            child: ExcludeSemantics(
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                maxLines: maxLines,
                onTapOutside: (_) => dismissKeyboard(context),
                style: registrationFieldInputStyle(context),
                decoration: registrationFieldDecoration(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
