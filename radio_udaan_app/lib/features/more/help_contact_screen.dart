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
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _subjectFocus = FocusNode();
  final _messageFocus = FocusNode();
  final _nameKey = GlobalKey();
  final _emailKey = GlobalKey();
  final _subjectKey = GlobalKey();
  final _messageKey = GlobalKey();
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
    _nameFocus.dispose();
    _emailFocus.dispose();
    _subjectFocus.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  void _validationError(
    String message, {
    GlobalKey? anchorKey,
    FocusNode? focusNode,
  }) {
    setState(() => _error = message);
    announceValidationError(context, message);
    revealFieldForValidation(
      context,
      anchorKey: anchorKey,
      focusNode: focusNode,
    );
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
      _validationError(
        '${_copy.nameLabel}, ${_copy.registrationFieldRequired}',
        anchorKey: _nameKey,
        focusNode: _nameFocus,
      );
      return;
    }
    if (email.isEmpty) {
      _validationError(
        '${_copy.emailLabel}, ${_copy.registrationFieldRequired}',
        anchorKey: _emailKey,
        focusNode: _emailFocus,
      );
      return;
    }
    if (subject.isEmpty) {
      _validationError(
        '${_copy.helpSubject}, ${_copy.registrationFieldRequired}',
        anchorKey: _subjectKey,
        focusNode: _subjectFocus,
      );
      return;
    }
    if (message.isEmpty) {
      _validationError(
        '${_copy.helpMessage}, ${_copy.registrationFieldRequired}',
        anchorKey: _messageKey,
        focusNode: _messageFocus,
      );
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
      _validationError(parseApiError(e).message);
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
                  FormFieldAnchor(
                    anchorKey: _nameKey,
                    child: _field(
                      context,
                      _copy.nameLabel,
                      _nameController,
                      focusNode: _nameFocus,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  FormFieldAnchor(
                    anchorKey: _emailKey,
                    child: _field(
                      context,
                      _copy.emailLabel,
                      _emailController,
                      focusNode: _emailFocus,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  FormFieldAnchor(
                    anchorKey: _subjectKey,
                    child: _field(
                      context,
                      _copy.helpSubject,
                      _subjectController,
                      focusNode: _subjectFocus,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  FormFieldAnchor(
                    anchorKey: _messageKey,
                    child: _field(
                      context,
                      _copy.helpMessage,
                      _messageController,
                      focusNode: _messageFocus,
                      maxLines: 5,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (!_sending) _send();
                      },
                    ),
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
    FocusNode? focusNode,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
    int maxLines = 1,
  }) {
    final action = textInputAction ??
        (maxLines > 1 ? TextInputAction.newline : TextInputAction.done);

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
                focusNode: focusNode,
                keyboardType: keyboardType,
                maxLines: maxLines,
                textInputAction: action,
                onSubmitted: (value) {
                  if (action == TextInputAction.next) {
                    FocusScope.of(context).nextFocus();
                    return;
                  }
                  if (action == TextInputAction.newline) {
                    return;
                  }
                  dismissKeyboard(context);
                  onSubmitted?.call(value);
                },
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
