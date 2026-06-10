import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_strings.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/udaan_colors.dart';
import '../../core/utils/external_link.dart';
import '../../core/widgets/live_badge.dart';
import '../../core/models/radio_schedule.dart';
import '../../core/widgets/main_tab_app_bar.dart';
import 'live_now_playing.dart';
import 'radio_audio_service.dart';
import 'radio_favorites_storage.dart';
import 'radio_player_controller.dart';
import 'radio_schedule_sheet.dart';

/// Live stream home (Stitch Live screen; content from GET /config → live_radio).
class RadioTab extends ConsumerStatefulWidget {
  const RadioTab({super.key});

  @override
  ConsumerState<RadioTab> createState() => _RadioTabState();
}

class _RadioTabState extends ConsumerState<RadioTab> {
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    final ready = await ensureRadioAudioService();
    if (!mounted) return;
    if (ready) {
      ref.read(radioPlayerProvider.notifier).attachPlayerIfReady();
      setState(() => _volume = radioAudioHandler.player.volume);
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

  Future<void> _shareLive(String text) async {
    try {
      final result =
          await SharePlus.instance.share(ShareParams(text: text.trim()));
      if (!mounted) return;
      if (result.status == ShareResultStatus.unavailable) {
        await Clipboard.setData(ClipboardData(text: text));
        if (!mounted) return;
        _announce(AppStrings.shareCopied);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.shareCopied)),
        );
      }
    } catch (_) {
      if (!mounted) return;
      _announce(AppStrings.shareFailed);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.shareFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(appBrandingProvider);
    final copy = ref.watch(appCopyProvider);
    final live = ref.watch(liveRadioProvider);
    final player = ref.watch(radioPlayerProvider);
    final notifier = ref.read(radioPlayerProvider.notifier);
    final scheduleAsync = ref.watch(radioScheduleProvider);
    final nowPlaying = ref.watch(liveNowPlayingProvider);
    final remoteConfig = ref.watch(remoteConfigProvider);

    // Live tab: Play → (loading) → Stop → Play only.
    final isLoading = player.status == RadioPlayerStatus.loading;
    final isPlaying = player.status == RadioPlayerStatus.playing;

    final next = scheduleAsync.valueOrNull?.next;
    final heroTitle = nowPlaying.title;
    final heroHosts = nowPlaying.hostsLine;
    final heroImageUrl = nowPlaying.imageUrl;

    final shareText = [
      live.shareText.trim(),
      (remoteConfig?.siteUrl ?? '').trim(),
    ].where((e) => e.isNotEmpty).join('\n\n');

    ref.listen<RadioPlayerState>(radioPlayerProvider, (previous, next) {
      if (previous?.status == next.status &&
          previous?.errorMessage == next.errorMessage) {
        return;
      }
      switch (next.status) {
        case RadioPlayerStatus.loading:
          _announce(AppStrings.radioConnecting);
        case RadioPlayerStatus.playing:
          _announce(AppStrings.radioPlaying);
        case RadioPlayerStatus.idle:
          if (previous?.status == RadioPlayerStatus.playing ||
              previous?.status == RadioPlayerStatus.loading) {
            _announce(AppStrings.radioStopped);
          }
        case RadioPlayerStatus.error:
          _announce(next.errorMessage ?? AppStrings.radioPlaybackError);
      }
    });

    return Scaffold(
      backgroundColor: UdaanColors.background,
      appBar: MainTabAppBar(title: branding.appName),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(BrandTokens.screenPadding),
          children: [
            const SizedBox(height: 4),
            const Center(child: LiveBadge()),
            const SizedBox(height: 16),
            _HeroCard(
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
                        notifier.play();
                      }
                    },
            ),
            if (player.errorMessage != null) ...[
              const SizedBox(height: 12),
              Semantics(
                label: player.errorMessage,
                liveRegion: true,
                child: Text(
                  player.errorMessage!,
                  style: const TextStyle(
                    color: UdaanColors.error,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (live.showVolume) ...[
              const SizedBox(height: 18),
              _VolumeCard(
                value: _volume,
                onChanged: (v) async {
                  setState(() => _volume = v);
                  try {
                    await radioAudioHandler.player.setVolume(v);
                  } catch (_) {
                    // Best-effort volume control.
                  }
                },
              ),
            ],
            if (live.showWhatsapp && live.hasWhatsappUrl) ...[
              const SizedBox(height: 18),
              _WhatsAppCard(
                title: live.whatsappLabel,
                subtitle: AppStrings.joinTheDiscussion,
                onPressed: () => openExternalUrl(context, live.whatsappUrl),
                accent: branding.colors.secondary,
              ),
            ],
            const SizedBox(height: 18),
            _UpcomingSegmentsCard(
              next: next,
              onOpenSchedule: () => showRadioScheduleSheet(context),
            ),
            const SizedBox(height: 16),
            _ActionRow(
              onShare: live.showShare ? () => _shareLive(shareText) : null,
              shareLabel: live.shareLabel,
              favoriteShowId: (nowPlaying.showId.isNotEmpty
                      ? nowPlaying.showId
                      : next?.id ?? '')
                  .trim(),
              favoriteShowTitle: heroTitle,
              onFavoriteToggled: _announce,
            ),
            if (copy.radioIntro.isNotEmpty) ...[
              const SizedBox(height: 12),
              Semantics(
                label: copy.radioIntro,
                child: Text(
                  copy.radioIntro,
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: UdaanColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.hosts,
    required this.heroImageUrl,
    required this.loading,
    required this.isPlaying,
    required this.onToggle,
  });

  final String title;
  final String hosts;
  final String heroImageUrl;
  final bool loading;
  final bool isPlaying;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
        border: Border.all(color: UdaanColors.outlineVariant),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 260,
              width: double.infinity,
              child: heroImageUrl.isNotEmpty
                  ? Semantics(
                      label: title,
                      image: true,
                      child: CachedNetworkImage(
                        key: ValueKey(heroImageUrl),
                        imageUrl: heroImageUrl,
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 300),
                        memCacheHeight: 520,
                        placeholder: (_, _) => const _HeroPlaceholder(),
                        errorWidget: (_, _, _) => const _HeroPlaceholder(),
                      ),
                    )
                  : const _HeroPlaceholder(),
            ),
          ),
          const SizedBox(height: 16),
          ExcludeSemantics(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: UdaanColors.onBackground,
              ),
            ),
          ),
          if (hosts.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              hosts,
              textAlign: TextAlign.center,
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: UdaanColors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 18),
          _PlayButton(
            loading: loading,
            isPlaying: isPlaying,
            onPressed: onToggle,
            primary: primary,
          ),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.loading,
    required this.isPlaying,
    required this.onPressed,
    required this.primary,
  });

  final bool loading;
  final bool isPlaying;
  final VoidCallback? onPressed;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final ring = isPlaying && !loading
        ? UdaanColors.primary
        : UdaanColors.outlineVariant;

    return Semantics(
      button: true,
      enabled: !loading,
      label: loading
          ? AppStrings.radioConnecting
          : isPlaying
              ? AppStrings.radioStop
              : AppStrings.radioPlay,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: BrandTokens.minTapTarget,
          minHeight: BrandTokens.minTapTarget,
        ),
        child: InkResponse(
          onTap: onPressed,
          radius: 56,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ring, width: 5),
              color: Colors.black,
            ),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: UdaanColors.primaryGlow,
                      ),
                    )
                  : Icon(
                      isPlaying ? Icons.stop : Icons.play_arrow,
                      size: 52,
                      color: primary,
                    ),
            ),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: UdaanColors.outlineVariant),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            UdaanColors.surfaceContainerHigh,
            UdaanColors.surfaceContainerHigh.withValues(alpha: 0.65),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.mic_none_outlined,
          size: 96,
          color: UdaanColors.primaryGlow,
        ),
      ),
    );
  }
}

class _VolumeCard extends StatelessWidget {
  const _VolumeCard({
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: UdaanColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: UdaanColors.outlineVariant),
      ),
      child: Row(
        children: [
          const ExcludeSemantics(
            child: Icon(Icons.volume_down_outlined, color: UdaanColors.primaryGlow),
          ),
          Expanded(
            child: Semantics(
              label: AppStrings.radioVolume,
              value: '${(value * 100).round()} percent',
              child: Slider(
                value: value.clamp(0, 1),
                onChanged: onChanged,
                activeColor: UdaanColors.primary,
              ),
            ),
          ),
          const ExcludeSemantics(
            child: Icon(Icons.volume_up_outlined, color: UdaanColors.primaryGlow),
          ),
        ],
      ),
    );
  }
}

class _WhatsAppCard extends StatelessWidget {
  const _WhatsAppCard({
    required this.title,
    required this.subtitle,
    required this.onPressed,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final VoidCallback onPressed;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title, $subtitle',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: UdaanColors.surfaceContainer,
            borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
            border: Border.all(color: UdaanColors.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.chat_bubble_outline, color: Colors.black),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: UdaanColors.onBackground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: UdaanColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: UdaanColors.primaryGlow),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingSegmentsCard extends StatelessWidget {
  const _UpcomingSegmentsCard({
    required this.next,
    required this.onOpenSchedule,
  });

  final RadioScheduleSegment? next;
  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    final title = next?.title.trim().isNotEmpty == true
        ? next!.title
        : AppStrings.radioUpcomingNone;

    final subtitleParts = <String>[
      if ((next?.timeRangeLabel() ?? '').isNotEmpty) next!.timeRangeLabel(),
      if ((next?.hosts ?? '').trim().isNotEmpty) next!.hosts,
    ];
    final subtitle = subtitleParts.join(' • ');

    return Container(
      decoration: BoxDecoration(
        color: UdaanColors.surfaceContainer,
        borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
        border: Border.all(color: UdaanColors.outlineVariant),
      ),
      child: Semantics(
        button: true,
        label: AppStrings.radioUpcomingSegmentsLabel(
          segmentTitle: title,
          subtitle: subtitle,
        ),
        child: InkWell(
          onTap: onOpenSchedule,
          borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                const Icon(Icons.schedule, color: UdaanColors.primaryGlow),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.radioUpcomingSegments,
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: UdaanColors.primaryGlow,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: UdaanColors.onBackground,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: UdaanColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.radioViewFullSchedule,
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: UdaanColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: UdaanColors.primaryGlow),
              ],
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
    required this.onFavoriteToggled,
  });

  final VoidCallback? onShare;
  final String shareLabel;
  final String favoriteShowId;
  final String favoriteShowTitle;
  final ValueChanged<String> onFavoriteToggled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasFavorite = favoriteShowId.trim().isNotEmpty;
    final favorites = ref.watch(radioFavoritesProvider);
    final isFavorite = hasFavorite && favorites.contains(favoriteShowId.trim());
    final shareText = shareLabel.trim().isNotEmpty
        ? shareLabel
        : AppStrings.radioShareLive;

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
            label: AppStrings.radioFavorite,
            icon: isFavorite ? Icons.favorite : Icons.favorite_border,
            onPressed: hasFavorite
                ? () async {
                    await ref
                        .read(radioFavoritesProvider.notifier)
                        .toggle(favoriteShowId);
                    final showTitle = favoriteShowTitle.trim().isNotEmpty
                        ? favoriteShowTitle.trim()
                        : AppStrings.unknown;
                    onFavoriteToggled(
                      AppStrings.radioFavoriteAnnouncement(
                        showTitle: showTitle,
                        added: !isFavorite,
                      ),
                    );
                  }
                : null,
            isActive: isFavorite,
            semanticsLabel: hasFavorite
                ? AppStrings.radioFavoriteButtonLabel(
                    showTitle: favoriteShowTitle.trim().isNotEmpty
                        ? favoriteShowTitle.trim()
                        : AppStrings.unknown,
                    isFavorite: isFavorite,
                  )
                : AppStrings.radioFavoriteAdd,
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
        isActive ? UdaanColors.primary : UdaanColors.outlineVariant;
    final background = isActive
        ? UdaanColors.primary.withValues(alpha: 0.14)
        : UdaanColors.surfaceContainer;
    final iconColor = enabled
        ? (isActive ? UdaanColors.primary : UdaanColors.primaryGlow)
        : UdaanColors.onSurfaceVariant.withValues(alpha: 0.45);
    final labelColor = enabled
        ? UdaanColors.onBackground
        : UdaanColors.onSurfaceVariant.withValues(alpha: 0.45);

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticsLabel,
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
    );
  }
}
