import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/accessibility/udaan_semantics.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/accessibility_scope.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/udaan_text_styles.dart';
import '../../features/auth/widgets/udaan_auth_widgets.dart';

class ForceUpdateScreen extends ConsumerWidget {
  const ForceUpdateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = ref.watch(appCopyProvider);
    final buildNumber = ref.watch(appBuildNumberProvider);
    final forceState = ref.watch(forceUpdateStateProvider);
    final remoteConfig = ref.watch(remoteConfigProvider);
    final palette = context.udaan;

    final currentBuildText = buildNumber == null
        ? ''
        : copy.forceUpdateCurrentBuild.replaceAll(
            '{build}',
            buildNumber.toString(),
          );

    final message = currentBuildText.isEmpty
        ? copy.forceUpdateMessage
        : '${copy.forceUpdateMessage}\n$currentBuildText';

    return PopScope(
      // Block back-navigation; the store update is the only recovery path.
      canPop: false,
      child: Scaffold(
        backgroundColor: palette.background,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BrandTokens.screenPadding,
                ),
                child: UdaanScreenHeader(
                  title: copy.forceUpdateTitle,
                  style: udaanTextStyle(
                    context,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: palette.onBackground,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BrandTokens.screenPadding,
                  ),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: UdaanLabeledRegion(
                          label: copy.forceUpdateMessage,
                          liveRegion: true,
                          child: Text(
                            message,
                            style: udaanTextStyle(
                              context,
                              fontSize: 16,
                              color: palette.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      UdaanPrimaryButton(
                        label: copy.forceUpdateButton,
                        icon: Icons.system_update,
                        onPressed: () async {
                          final url = forceState.storeUrl;
                          if (url == null || url.trim().isEmpty) {
                            announceAndSnack(
                              context,
                              'Update link is not configured in WP Admin.',
                            );
                            return;
                          }

                          final uri = Uri.tryParse(url.trim());
                          if (uri == null || !uri.hasScheme) {
                            announceAndSnack(
                              context,
                              'Update link is invalid. Please contact support.',
                            );
                            return;
                          }

                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                      if ((remoteConfig?.support.helplinePhone?.isNotEmpty ??
                              false))
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: UdaanOutlineButton(
                            label: 'Call support helpline',
                            icon: Icons.phone,
                            onPressed: () async {
                              final phone = remoteConfig
                                      ?.support.helplinePhone?.trim() ??
                                  '';
                              if (phone.isEmpty) return;
                              final uri = Uri(
                                scheme: 'tel',
                                path: phone,
                              );
                              if (!await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              )) {
                                announce(context, 'Could not open phone app.');
                              }
                            },
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

