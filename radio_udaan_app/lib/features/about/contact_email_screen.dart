import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/accessibility_scope.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/udaan_google_fonts.dart';
import '../../core/widgets/brand_app_bar.dart';
import '../auth/widgets/udaan_auth_widgets.dart';

/// Shows support email from WordPress with mail + copy actions.
class ContactEmailScreen extends ConsumerWidget {
  const ContactEmailScreen({super.key});

  void _announce(BuildContext context, String message) {
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.of(context),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = ref.watch(appCopyProvider);
    final email =
        ref.watch(remoteConfigProvider)?.support.email?.trim() ?? '';
    final palette = context.udaan;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: BrandAppBar(title: copy.contactEmailTitle),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BrandTokens.screenPadding),
          child: email.isEmpty
              ? Semantics(
                  label: copy.linkUnavailable,
                  liveRegion: true,
                  child: ExcludeSemantics(
                    child: Text(                    copy.linkUnavailable,
                    style: udaanGoogleFont(
                      context,
                      fontSize: 16,
                      color: palette.onSurfaceVariant,
                    ),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        copy.contactEmailSubtitle,
                        style: udaanGoogleFont(
                          context,
                          fontSize: 16,
                          color: palette.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: palette.surfaceContainer,
                        borderRadius:
                            BorderRadius.circular(BrandTokens.cardRadius),
                        border: Border.all(color: palette.outlineVariant),
                      ),
                      child: SelectableText(
                        email,
                        style: udaanGoogleFont(
                          context,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: palette.primaryGlow,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    UdaanPrimaryButton(
                      label: copy.emailSupport,
                      icon: Icons.mail_outline,
                      onPressed: () async {
                        final uri = Uri(scheme: 'mailto', path: email);
                        if (!await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        )) {
                          if (!context.mounted) return;
                          _announce(context, copy.linkOpenFailed);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    UdaanOutlineButton(
                      label: copy.copyValue,
                      icon: Icons.copy,
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: email));
                        if (!context.mounted) return;
                        _announce(context, copy.copiedToClipboard);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(copy.copiedToClipboard)),
                        );
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
