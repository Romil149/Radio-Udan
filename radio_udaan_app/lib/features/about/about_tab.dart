import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/udaan_colors.dart';
import '../../core/utils/external_link.dart';
import '../../core/widgets/main_tab_app_bar.dart';
import '../more/help_contact_screen.dart';
import '../more/widgets/more_hero_card.dart';
import '../more/widgets/more_menu_tile.dart';
import 'about_us_screen.dart';
import 'contact_email_screen.dart';
import 'contact_phone_screen.dart';
import 'donate_screen.dart';
import 'whats_new_list_screen.dart';
import 'widgets/about_social_footer.dart';

/// About tab: organisation info, contact, donate, and social links.
class AboutTab extends ConsumerWidget {
  const AboutTab({super.key});

  static void _announce(BuildContext context, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      );
    });
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = ref.watch(appCopyProvider);
    final config = ref.watch(remoteConfigProvider);
    final supportEmail = config?.support.email?.trim() ?? '';
    final supportPhone = config?.support.helplinePhone?.trim() ?? '';
    final social = config?.infoHub.social ?? const [];
    final live = config?.liveRadio;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: MainTabAppBar(title: copy.tabAbout),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            MoreHeroCard(
              title: copy.aboutOptionsTitle,
              intro: copy.aboutOptionsIntro,
              backgroundIcon: Icons.info_outline,
            ),
            MoreMenuTile(
              title: copy.aboutUs,
              subtitle: copy.aboutUsSubtitle,
              icon: Icons.info_outline,
              iconBackground: context.udaan.secondary,
              onTap: () => _push(context, const AboutUsScreen()),
            ),
            MoreMenuTile(
              title: copy.aboutWhatsNew,
              subtitle: copy.aboutWhatsNewSubtitle,
              icon: Icons.campaign_outlined,
              iconBackground: context.udaan.primary,
              onTap: () => _push(context, const WhatsNewListScreen()),
            ),
            MoreMenuTile(
              title: copy.helpAndContact,
              subtitle: copy.helpAndContactSubtitle,
              icon: Icons.support_agent,
              iconBackground: context.udaan.surfaceContainerHigh,
              iconColor: context.udaan.onBackground,
              onTap: () => _push(context, const HelpContactScreen()),
            ),
            MoreMenuTile(
              title: copy.contactEmailTitle,
              subtitle: supportEmail.isNotEmpty
                  ? supportEmail
                  : copy.contactEmailSubtitle,
              icon: Icons.mail_outline,
              iconBackground: context.udaan.primary,
              onTap: supportEmail.isNotEmpty
                  ? () => _push(context, const ContactEmailScreen())
                  : () {
                      _announce(context, copy.linkUnavailable);
                    },
            ),
            MoreMenuTile(
              title: copy.contactNumberTitle,
              subtitle: supportPhone.isNotEmpty
                  ? supportPhone
                  : copy.contactNumberSubtitle,
              icon: Icons.phone_outlined,
              iconBackground: context.udaan.secondary,
              onTap: supportPhone.isNotEmpty
                  ? () => _push(context, const ContactPhoneScreen())
                  : () {
                      _announce(context, copy.linkUnavailable);
                    },
            ),
            if (live != null && live.showWhatsapp && live.hasWhatsappUrl)
              MoreMenuTile(
                title: live.whatsappLabel,
                subtitle: copy.joinTheDiscussion,
                icon: Icons.chat_outlined,
                iconBackground: context.udaan.secondary,
                onTap: () => openExternalUrl(
                  context,
                  live.whatsappUrl,
                  copy: copy,
                ),
              ),
            MoreMenuTile(
              title: copy.donateUs,
              subtitle: copy.donateUsSubtitle,
              icon: Icons.favorite_outline,
              iconBackground: context.udaan.primary,
              onTap: () => _push(context, const DonateScreen()),
            ),
            AboutSocialFooter(
              copy: copy,
              links: social,
              onLaunchFailed: () {
                _announce(context, copy.linkOpenFailed);
              },
            ),
          ],
        ),
      ),
    );
  }
}
