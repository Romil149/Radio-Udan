import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/accessibility/udaan_semantics.dart';
import '../../core/config/app_store_share.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/accessibility_scope.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/udaan_colors.dart';
import '../../core/theme/udaan_google_fonts.dart';
import '../../core/models/radio_schedule.dart';
import '../../core/widgets/main_tab_app_bar.dart';
import 'azuracast_now_playing_provider.dart';
import 'live_now_playing.dart';
import '../favorites/app_favorites_provider.dart';
import 'radio_player_controller.dart';
import 'radio_schedule_provider.dart';
import 'radio_schedule_sheet.dart';
import 'widgets/radio_volume_control.dart';

/// Live stream home (Stitch Live screen; content from GET /config → live_radio).
class RadioTab extends ConsumerStatefulWidget {
  const RadioTab({super.key});

  @override
  ConsumerState<RadioTab> createState() => _RadioTabState();
}

class _RadioTabState extends ConsumerState<RadioTab> {
  AppCopy get _copy => ref.read(appCopyProvider);

  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(azuracastNowPlayingProvider.notifier).startPolling();
    });
  }

  @override
  void dispose() {
    ref.read(azuracastNowPlayingProvider.notifier).stopPolling();
    super.dispose();
  }

  Future<void> _shareApp() async {
    final remoteConfig = ref.read(remoteConfigProvider);
    final live = ref.read(liveRadioProvider);
    final message = buildAppShareMessage(
      message: live.shareText.trim().isNotEmpty
          ? live.shareText
          : _copy.radioShareTextFallback,
      appStoreUrl: remoteConfig?.appStoreUrl,
      playStoreUrl: remoteConfig?.playStoreUrl,
    );

    if (message.trim().isEmpty ||
        storeListingUrl(
              appStoreUrl: remoteConfig?.appStoreUrl,
              playStoreUrl: remoteConfig?.playStoreUrl,
            ) ==
            null) {
      if (!mounted) return;
      announceAndSnack(context, _copy.shareUnavailable);
      return;
    }

    try {
      final result =
          await SharePlus.instance.share(ShareParams(text: message.trim()));
      if (!mounted) return;
      if (result.status == ShareResultStatus.unavailable) {
        await Clipboard.setData(ClipboardData(text: message));
        if (!mounted) return;
        announceAndSnack(context, _copy.shareCopied);
      }
    } catch (_) {
      if (!mounted) return;
      announceAndSnack(context, _copy.shareFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(liveRadioProvider);
    final player = ref.watch(radioPlayerProvider);
    final notifier = ref.read(radioPlayerProvider.notifier);
    final scheduleAsync = ref.watch(radioScheduleProvider);
    final nowPlaying = ref.watch(liveNowPlayingProvider);

    // Live tab: Play → (loading) → Stop → Play only.
    final isLoading = player.status == RadioPlayerStatus.loading;
    final isPlaying = player.status == RadioPlayerStatus.playing;

    final next = scheduleAsync.valueOrNull?.next;
    final azuraUpcoming = ref.watch(azuracastUpcomingProvider);
    final heroTitle = nowPlaying.title;
    final heroHosts = nowPlaying.hostsLine;
    final heroImageUrl = nowPlaying.imageUrl;

    ref.listen<RadioPlayerState>(radioPlayerProvider, (previous, next) {
      if (previous?.status == next.status &&
          previous?.errorMessage == next.errorMessage) {
        return;
      }
      // Play/stop state is conveyed by the hero card semantics label.
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: MainTabAppBar(title: _copy.tabRadio),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(BrandTokens.screenPadding),
          children: [
            _HeroCard(
              copy: _copy,
              title: heroTitle,
              hosts: heroHosts,
              heroImageUrl: heroImageUrl,
              loading: isLoading,
              isPlaying: isPlaying,
              onToggle: isLoading
                  ? null
                  : () {
                      if (isPlaying) {
                        notifier.stop();
                      } else {
                        notifier.play(volume: _volume);
                      }
                    },
            ),
            if (player.errorMessage != null) ...[
              const SizedBox(height: 12),
              Semantics(
                label: player.errorMessage,
                liveRegion: true,
                child: ExcludeSemantics(
                  child: Text(
                    player.errorMessage!,
                    style: TextStyle(
                      color: context.udaan.error,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
            if (live.showVolume) ...[
              const SizedBox(height: 18),
              RadioVolumeControl(
                copy: _copy,
                value: _volume,
                onChanged: (v) {
                  setState(() => _volume = v);
                  unawaited(
                    ref.read(radioPlayerProvider.notifier).applyVolumePreference(v),
                  );
                },
              ),
            ],
            const SizedBox(height: 18),
            _UpcomingSegmentsCard(
              copy: _copy,
              next: next,
              azuraNextTitle: azuraUpcoming?.title,
              azuraNextSubtitle: azuraUpcoming?.subtitle,
              onOpenSchedule: () => showRadioScheduleSheet(context),
            ),
            const SizedBox(height: 16),
            _ActionRow(
              onShare: live.showShare ? _shareApp : null,
              shareLabel: live.shareLabel,
              favoriteShowId: nowPlaying.isOnAir ? nowPlaying.showId : '',
              favoriteShowTitle:
                  nowPlaying.isOnAir ? heroTitle : '',
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.copy,
    required this.title,
    required this.hosts,
    required this.heroImageUrl,
    required this.loading,
    required this.isPlaying,
    required this.onToggle,
  });

  final AppCopy copy;
  final String title;
  final String hosts;
  final String heroImageUrl;
  final bool loading;
  final bool isPlaying;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final palette = context.udaan;

    final semanticsLabel = copy.radioPlayButtonSemantics(
      loading: loading,
      isPlaying: isPlaying,
      showTitle: title,
      hostsLine: hosts,
    );

    return Semantics(
      button: true,
      enabled: !loading && onToggle != null,
      label: semanticsLabel,
      onTap: loading ? null : onToggle,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: loading ? null : onToggle,
            borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              decoration: BoxDecoration(
                color: palette.surfaceContainer,
                borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
                border: Border.all(color: palette.outlineVariant),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 260,
                      width: double.infinity,
                      child: heroImageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              key: ValueKey(heroImageUrl),
                              imageUrl: heroImageUrl,
                              fit: BoxFit.cover,
                              fadeInDuration:
                                  const Duration(milliseconds: 300),
                              memCacheHeight: 520,
                              placeholder: (_, _) =>
                                  const _HeroPlaceholder(),
                              errorWidget: (_, _, _) =>
                                  const _HeroPlaceholder(),
                            )
                          : const _HeroPlaceholder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: udaanGoogleFont(
                      context,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: palette.onBackground,
                    ),
                  ),
                  if (hosts.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      hosts,
                      textAlign: TextAlign.center,
                      style: udaanGoogleFont(
                        context,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: palette.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _PlayButtonVisual(
                    loading: loading,
                    isPlaying: isPlaying,
                    primary: primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayButtonVisual extends StatelessWidget {
  const _PlayButtonVisual({
    required this.loading,
    required this.isPlaying,
    required this.primary,
  });

  final bool loading;
  final bool isPlaying;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final ring = isPlaying && !loading
        ? context.udaan.primary
        : context.udaan.outlineVariant;

    return SizedBox(
      width: 96,
      height: 96,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ring, width: 5),
          color: context.udaan.surfaceDark,
        ),
        child: Center(
          child: loading
              ? SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: context.udaan.primaryGlow,
                  ),
                )
              : Icon(
                  isPlaying ? Icons.stop : Icons.play_arrow,
                  size: 52,
                  color: primary,
                ),
        ),
      ),
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: context.udaan.outlineVariant),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.udaan.surfaceContainerHigh,
              context.udaan.surfaceContainerHigh.withValues(alpha: 0.65),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.mic_none_outlined,
            size: 96,
            color: context.udaan.primaryGlow,
          ),
        ),
      ),
    );
  }
}

class _UpcomingSegmentsCard extends StatelessWidget {
  const _UpcomingSegmentsCard({
    required this.copy,
    required this.next,
    required this.onOpenSchedule,
    this.azuraNextTitle,
    this.azuraNextSubtitle,
  });

  final AppCopy copy;
  final RadioScheduleSegment? next;
  final VoidCallback onOpenSchedule;
  final String? azuraNextTitle;
  final String? azuraNextSubtitle;

  @override
  Widget build(BuildContext context) {
    final azuraTitle = azuraNextTitle?.trim() ?? '';
    final title = azuraTitle.isNotEmpty
        ? azuraTitle
        : (next?.title.trim().isNotEmpty == true
            ? next!.title
            : copy.radioUpcomingNone);

    final subtitleParts = <String>[
      if ((azuraNextSubtitle ?? '').trim().isNotEmpty)
        azuraNextSubtitle!.trim()
      else ...[
        if ((next?.timeRangeLabel() ?? '').isNotEmpty) next!.timeRangeLabel(),
        if (next != null && next!.hosts.trim().isNotEmpty)
          formatRadioHostsLine(next!.hosts, copy),
      ],
    ];
    final subtitle = subtitleParts.join(' • ');

    return Container(
      decoration: BoxDecoration(
        color: context.udaan.surfaceContainer,
        borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
        border: Border.all(color: context.udaan.outlineVariant),
      ),
      child: Semantics(
        button: true,
        label: copy.radioUpcomingSegmentsLabel(
          segmentTitle: title,
          subtitle: subtitle,
        ),
        child: ExcludeSemantics(
          child: InkWell(
            onTap: onOpenSchedule,
            borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: context.udaan.primaryGlow),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          copy.radioUpcomingSegments,
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: context.udaan.primaryGlow,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: context.udaan.onBackground,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: context.udaan.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          copy.radioViewFullSchedule,
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: context.udaan.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: context.udaan.primaryGlow),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends ConsumerWidget {
  const _ActionRow({
    required this.onShare,
    required this.shareLabel,
    required this.favoriteShowId,
    required this.favoriteShowTitle,
  });

  final VoidCallback? onShare;
  final String shareLabel;
  final String favoriteShowId;
  final String favoriteShowTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = ref.watch(appCopyProvider);
    final hasFavorite = favoriteShowId.trim().isNotEmpty;
    final favorites = ref.watch(radioFavoritesProvider);
    final isFavorite = hasFavorite && favorites.contains(favoriteShowId.trim());
    final shareText = shareLabel.trim().isNotEmpty
        ? shareLabel
        : copy.radioShareLive;

    return Row(
      children: [
        Expanded(
          child: _LiveActionButton(
            label: shareText,
            icon: Icons.share_outlined,
            onPressed: onShare,
            semanticsLabel: shareText,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _LiveActionButton(
            label: copy.radioFavorite,
            icon: isFavorite ? Icons.favorite : Icons.favorite_border,
            onPressed: hasFavorite
                ? () async {
                    await ref.read(appFavoritesProvider.notifier).toggleRadioShow(
                          showId: favoriteShowId,
                          title: favoriteShowTitle.trim().isNotEmpty
                              ? favoriteShowTitle.trim()
                              : copy.unknown,
                        );
                  }
                : null,
            isActive: isFavorite,
            semanticsLabel: hasFavorite
                ? copy.radioFavoriteButtonLabel(
                    showTitle: favoriteShowTitle.trim().isNotEmpty
                        ? favoriteShowTitle.trim()
                        : copy.unknown,
                    isFavorite: isFavorite,
                  )
                : copy.radioFavoriteAdd,
          ),
        ),
      ],
    );
  }
}

/// Matching pill actions for Share + Favorite (Stitch: 56px, outlined, labeled).
class _LiveActionButton extends StatelessWidget {
  const _LiveActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.semanticsLabel,
    this.isActive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticsLabel;
  final bool isActive;

  static const double _height = 56;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final borderColor =
        isActive ? context.udaan.primary : context.udaan.outlineVariant;
    final background = isActive
        ? context.udaan.primary.withValues(alpha: 0.14)
        : context.udaan.surfaceContainer;
    final iconColor = enabled
        ? (isActive ? context.udaan.primary : context.udaan.primaryGlow)
        : context.udaan.onSurfaceVariant.withValues(alpha: 0.45);
    final labelColor = enabled
        ? context.udaan.onBackground
        : context.udaan.onSurfaceVariant.withValues(alpha: 0.45);

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(_height / 2),
            child: Ink(
              height: _height,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(_height / 2),
                border: Border.all(
                  color: borderColor,
                  width: isActive ? 2 : 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22, color: iconColor),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: labelColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
