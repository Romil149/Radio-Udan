import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/network/dio_exception_mapper.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/udaan_colors.dart';
import '../auth/widgets/udaan_auth_widgets.dart';
import '../events/widgets/registration_form_styles.dart';
import 'widgets/contact_support_actions_card.dart';

/// Contact form + direct support actions (email / helpline).
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

  Future<void> _send() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    if (name.isEmpty || email.isEmpty || subject.isEmpty || message.isEmpty) {
      setState(() => _error = _copy.registrationFieldRequired);
      _announce(_copy.registrationFieldRequired);
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
      setState(() {
        _success = _copy.messageSent;
        _subjectController.clear();
        _messageController.clear();
      });
      if (mounted) {
        SemanticsService.sendAnnouncement(
          View.of(context),
          _copy.messageSent,
          Directionality.of(context),
        );
      }
    } catch (e) {
      final message = parseApiError(e).message;
      setState(() => _error = message);
      _announce(message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
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

  void _launchFailed() {
    if (!mounted) return;
    _announce(_copy.linkOpenFailed);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_copy.linkOpenFailed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = ref.watch(appCopyProvider);
    final config = ref.watch(remoteConfigProvider);
    final support = config?.support;
    final supportEmail = support?.email ?? '';
    final helpline = support?.helplinePhone ?? '';

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
                    child: Text(
                      _copy.contactFormTitle,
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: UdaanColors.primaryGlow,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _copy.contactFormIntro,
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: UdaanColors.onSurfaceVariant,
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
                      liveRegion: true,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: UdaanColors.error),
                        ),
                      ),
                    ),
                  if (_success != null)
                    Semantics(
                      liveRegion: true,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _success!,
                          style: const TextStyle(color: UdaanColors.secondary),
                        ),
                      ),
                    ),
                  UdaanPrimaryButton(
                    label: _copy.sendMessage,
                    icon: Icons.send_outlined,
                    loading: _sending,
                    onPressed: _sending ? null : _send,
                  ),
                  const SizedBox(height: 24),
                  ContactSupportActionsCard(
                    copy: copy,
                    supportEmail: supportEmail,
                    helplinePhone: helpline,
                    onLaunchFailed: _launchFailed,
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
          Text(label, style: registrationFieldLabelStyle(context)),
          const SizedBox(height: 8),
          Semantics(
            label: '$label, required',
            textField: true,
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              style: registrationFieldInputStyle(context),
              decoration: registrationFieldDecoration(context),
            ),
          ),
        ],
      ),
    );
  }
}
