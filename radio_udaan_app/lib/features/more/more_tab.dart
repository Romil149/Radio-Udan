import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_error.dart';
import '../../core/config/remote_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/network/dio_exception_mapper.dart';
import '../../core/providers/app_providers.dart';
import '../../core/storage/registration_draft_storage.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/udaan_colors.dart';
import '../auth/auth_session_helper.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/main_tab_app_bar.dart';
import 'edit_profile_screen.dart';
import 'help_contact_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'notifications_providers.dart';
import 'widgets/more_hero_card.dart';
import 'widgets/more_menu_tile.dart';

/// Profile, settings, help, legal links, account deletion, and logout.
class MoreTab extends ConsumerWidget {
  const MoreTab({super.key});

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
    final user = ref.watch(authUserProvider);
    final token = ref.watch(authTokenProvider);
    final config = ref.watch(remoteConfigProvider);
    final isSignedIn = token != null && token.isNotEmpty;
    final unreadCount = ref.watch(notificationUnreadCountProvider).value ?? 0;

    return Scaffold(
      backgroundColor: UdaanColors.background,
      appBar: MainTabAppBar(
        title: copy.tabMore,
        onProfileTap: isSignedIn
            ? () => _push(context, const EditProfileScreen())
            : null,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(BrandTokens.screenPadding),
          children: [
            const MoreHeroCard(
              title: AppStrings.moreOptionsTitle,
              intro: AppStrings.moreOptionsIntro,
            ),
            if (isSignedIn) ...[
              MoreMenuTile(
                title: AppStrings.userProfile,
                subtitle: AppStrings.userProfileSubtitle,
                icon: Icons.person,
                iconBackground: UdaanColors.primary,
                onTap: () => _push(context, const EditProfileScreen()),
              ),
              MoreMenuTile(
                title: AppStrings.notificationsTitle,
                subtitle: unreadCount > 0
                    ? AppStrings.unreadNotificationsBadge(unreadCount)
                    : AppStrings.notificationsSubtitle,
                icon: Icons.notifications_outlined,
                iconBackground: UdaanColors.secondary,
                trailing: unreadCount > 0
                    ? ExcludeSemantics(
                        child: Badge(
                          label: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                          ),
                          backgroundColor: UdaanColors.primary,
                          child: const Icon(Icons.chevron_right),
                        ),
                      )
                    : null,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                  ref.invalidate(notificationUnreadCountProvider);
                },
              ),
              MoreMenuTile(
                title: AppStrings.settingsTitle,
                subtitle: AppStrings.settingsSubtitle,
                icon: Icons.tune,
                iconBackground: UdaanColors.surfaceContainerHigh,
                iconColor: UdaanColors.primaryGlow,
                onTap: () => _push(context, const SettingsScreen()),
              ),
            ],
            MoreMenuTile(
              title: AppStrings.helpAndContact,
              subtitle: AppStrings.helpAndContactSubtitle,
              icon: Icons.support_agent,
              iconBackground: UdaanColors.surfaceContainerHigh,
              iconColor: UdaanColors.onBackground,
              onTap: () => _push(context, const HelpContactScreen()),
            ),
            if (config?.aboutUrl != null)
              MoreMenuTile(
                title: AppStrings.aboutUs,
                subtitle: AppStrings.aboutUsSubtitle,
                icon: Icons.info_outline,
                iconBackground: UdaanColors.secondary,
                onTap: () => _openExternalUrl(context, config!.aboutUrl!),
              ),
            if (isSignedIn && user != null && !user.emailVerified) ...[
              const SizedBox(height: 4),
              MoreMenuTile(
                title: AppStrings.verifyEmailLink,
                subtitle: user.email != null && user.email!.isNotEmpty
                    ? '${user.email}. ${AppStrings.emailNotVerified}'
                    : AppStrings.emailNotVerified,
                icon: Icons.mark_email_unread_outlined,
                iconBackground: UdaanColors.primary,
                onTap: () => context.go(
                  '/verify-email',
                  extra: VerifyEmailRouteArgs(email: user.email ?? ''),
                ),
              ),
            ],
            if (config != null) ...[
              const SizedBox(height: 8),
              Semantics(
                header: true,
                label: AppStrings.legalSection,
                child: Text(
                  AppStrings.legalSection,
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: UdaanColors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ..._legalTiles(context, config),
            ],
            const SizedBox(height: 8),
            MoreMenuTile(
              title: AppStrings.deleteAccount,
              subtitle: AppStrings.deleteAccountSubtitle,
              semanticsLabel: isSignedIn
                  ? null
                  : '${AppStrings.deleteAccount}. ${AppStrings.deleteAccountSubtitle}. ${AppStrings.notSignedIn}',
              icon: Icons.delete_forever_outlined,
              iconBackground: UdaanColors.error.withValues(alpha: 0.2),
              iconColor: UdaanColors.error,
              titleColor: UdaanColors.error,
              onTap: isSignedIn
                  ? () => _confirmDeleteAccount(context, ref)
                  : null,
            ),
            MoreMenuTile(
              title: AppStrings.logout,
              subtitle: AppStrings.logoutSubtitle,
              semanticsLabel: isSignedIn
                  ? null
                  : '${AppStrings.logout}. ${AppStrings.logoutSubtitle}. ${AppStrings.notSignedIn}',
              icon: Icons.logout,
              iconBackground: UdaanColors.error.withValues(alpha: 0.15),
              iconColor: UdaanColors.error,
              titleColor: UdaanColors.primaryGlow,
              borderColor: UdaanColors.primaryGlow,
              trailing: const Icon(Icons.logout, color: UdaanColors.primaryGlow),
              onTap: isSignedIn ? () => _logout(context, ref) : null,
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Text(
                    AppStrings.appVersionLabel(AppConstants.appVersion),
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 14,
                      color: UdaanColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppStrings.madeWithAccessibility,
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 13,
                      color: UdaanColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _legalTiles(BuildContext context, RemoteConfig config) {
    final links = <({String title, String? url, IconData icon})>[
      (title: AppStrings.privacyPolicy, url: config.privacyPolicyUrl, icon: Icons.privacy_tip_outlined),
      (title: AppStrings.termsOfUse, url: config.termsUrl, icon: Icons.description_outlined),
    ];

    return [
      for (final link in links)
        if (link.url != null)
          MoreMenuTile(
            title: link.title,
            subtitle: AppStrings.linkOpensInBrowser,
            icon: link.icon,
            iconBackground: UdaanColors.surfaceContainerHigh,
            iconColor: UdaanColors.primaryGlow,
            onTap: () => _openExternalUrl(context, link.url!),
          ),
    ];
  }

  Future<void> _openExternalUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      if (context.mounted) {
        _announce(context, AppStrings.linkUnavailable);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.linkUnavailable)),
        );
      }
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        _announce(context, AppStrings.linkOpenFailed);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.linkOpenFailed)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        _announce(context, AppStrings.linkOpenFailed);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.linkOpenFailed)),
        );
      }
    }
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.deleteAccountConfirmTitle),
        content: const Text(AppStrings.deleteAccountConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text(AppStrings.deleteAccount),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await _deleteAccount(context, ref);
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(radioudaanApiProvider).deleteAccount();
    } catch (e) {
      final message = parseApiError(e).message;
      if (context.mounted) {
        _announce(context, message);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
      return;
    }

    final drafts = await RegistrationDraftStorage.create();
    await drafts.clearAll();
    await clearAuthSession(ref);
    if (context.mounted) {
      _announce(context, AppStrings.accountDeletedSigningOut);
      context.go('/login');
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(radioudaanApiProvider).logout();
    } on ApiError {
      // Token may already be expired; still clear local session.
    } catch (_) {}

    final drafts = await RegistrationDraftStorage.create();
    await drafts.clearAll();
    await clearAuthSession(ref);
    if (context.mounted) {
      _announce(context, AppStrings.signingOut);
      context.go('/login');
    }
  }
}
