import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/accessibility/udaan_semantics.dart';
import '../../core/models/radio_schedule.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/wp_media_url.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/udaan_colors.dart';
import 'live_now_playing.dart';
import '../favorites/app_favorites_provider.dart';
import 'schedule_time_display.dart';

/// Refreshes on a timer so hero title / RJ update when the slot changes.
final radioScheduleProvider = FutureProvider<RadioScheduleResponse>((ref) async {
  final timer = Timer.periodic(const Duration(minutes: 1), (_) {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  final api = ref.read(radioudaanApiProvider);
  return api.fetchRadioSchedule(days: 2);
});

Future<void> showRadioScheduleSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      final copy = ProviderScope.containerOf(context).read(appCopyProvider);
      return UdaanModalSheet(
        title: copy.radioScheduleTitle,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) => RadioScheduleSheet(
            scrollController: scrollController,
          ),
        ),
      );
    },
  );
}

class RadioScheduleSheet extends ConsumerWidget {
  const RadioScheduleSheet({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = ref.watch(appCopyProvider);
    final scheduleAsync = ref.watch(radioScheduleProvider);

    return SafeArea(
      top: false,
      child: Column(
        children: [
          const SizedBox(height: 4),
          UdaanScreenHeader(
            title: copy.radioScheduleTitle,
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: context.udaan.onBackground,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: scheduleAsync.when(
              data: (data) => _ScheduleList(
                schedule: data,
                scrollController: scrollController,
              ),
              loading: () => const _ScheduleLoading(),
              error: (_, _) => const _ScheduleError(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleList extends ConsumerWidget {
  const _ScheduleList({
    required this.schedule,
    required this.scrollController,
  });

  final RadioScheduleResponse schedule;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = ref.watch(appCopyProvider);
    final days = schedule.days;
    final onAirId = schedule.onAir?.id ?? '';
    final stationOffset =
        ScheduleTimeDisplay.stationOffsetFromSchedule(schedule);
    if (days.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(BrandTokens.screenPadding),
          child: Semantics(
            label: copy.radioScheduleEmpty,
            liveRegion: true,
            child: ExcludeSemantics(
              child: Text(              copy.radioScheduleEmpty,
              textAlign: TextAlign.center,
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.udaan.onSurfaceVariant,
              ),
              ),
            ),
          ),
        ),
      );
    }

    final timeFmt = DateFormat('h:mm a');
    final favorites = ref.watch(radioFavoritesProvider);

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        BrandTokens.screenPadding,
        0,
        BrandTokens.screenPadding,
        20,
      ),
      itemCount: days.length,
      itemBuilder: (context, i) {
        final day = days[i];
        return Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Semantics(
                    header: true,
                    label: day.displayLabel(),
                    child: ExcludeSemantics(
                      child: Text(
                        day.displayLabel(),
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: context.udaan.primaryGlow,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: context.udaan.outlineVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...day.segments.map(
                (segment) => _ScheduleSegmentCard(
                  segment: segment,
                  timeFmt: timeFmt,
                  stationOffset: stationOffset,
                  isFavorite: segment.hasId && favorites.contains(segment.id),
                  isOnAir: onAirId.isNotEmpty && segment.id == onAirId,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScheduleSegmentCard extends ConsumerWidget {
  const _ScheduleSegmentCard({
    required this.segment,
    required this.timeFmt,
    required this.stationOffset,
    required this.isFavorite,
    required this.isOnAir,
  });

  final RadioScheduleSegment segment;
  final DateFormat timeFmt;
  final Duration stationOffset;
  final bool isFavorite;
  final bool isOnAir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = ref.watch(appCopyProvider);
    final title =
        segment.title.isNotEmpty ? segment.title : copy.unknown;
    final time = ScheduleTimeDisplay.label(
      segment: segment,
      stationOffset: stationOffset,
      copy: copy,
      timeFormat: timeFmt,
    );
    final hostsLine = segment.hasHosts
        ? formatRadioHostsLine(segment.hosts, copy)
        : '';

    final segmentLabel = copy.radioScheduleSegmentSemantics(
      title: title,
      time: time,
      hosts: hostsLine,
      onAir: isOnAir,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      constraints:
          const BoxConstraints(minHeight: BrandTokens.minTapTarget + 16),
      decoration: BoxDecoration(
        color: context.udaan.surfaceContainer,
        borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
        border: Border.all(
          color: isOnAir ? context.udaan.primary : context.udaan.outlineVariant,
          width: isOnAir ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ExcludeSemantics(
              child: _SegmentThumbnail(imageUrl: segment.imageUrl, title: title),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: UdaanLabeledRegion(
                label: segmentLabel,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isOnAir) ...[
                      _ChipLabel(
                        text: copy.radioScheduleOnAir,
                        color: context.udaan.primary,
                        textColor: context.udaan.onPrimary,
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: context.udaan.onBackground,
                        height: 1.2,
                      ),
                    ),
                    if (time.isNotEmpty || segment.hasCategory) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (time.isNotEmpty)
                            _ChipLabel(
                              text: time,
                              color: context.udaan.surfaceContainerHigh,
                              textColor: context.udaan.primaryGlow,
                              icon: Icons.schedule_outlined,
                            ),
                          if (segment.hasCategory)
                            _ChipLabel(
                              text: segment.category,
                              color: context.udaan.surfaceContainerHigh,
                              textColor: context.udaan.onSurfaceVariant,
                            ),
                        ],
                      ),
                    ],
                    if (hostsLine.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        hostsLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.udaan.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Semantics(
                button: true,
                label: copy.radioFavoriteButtonLabel(
                  showTitle: title,
                  isFavorite: isFavorite,
                ),
                child: ExcludeSemantics(
                  child: IconButton(
                    constraints: const BoxConstraints(
                      minWidth: BrandTokens.minTapTarget,
                      minHeight: BrandTokens.minTapTarget,
                    ),
                    onPressed: segment.hasId
                        ? () async {
                            await ref
                                .read(appFavoritesProvider.notifier)
                                .toggleRadioShow(
                                  showId: segment.id,
                                  title: title,
                                  meta: {
                                    if (segment.imageUrl.trim().isNotEmpty)
                                      'thumbnail_url': segment.imageUrl.trim(),
                                    if (segment.hosts.trim().isNotEmpty)
                                      'hosts': segment.hosts.trim(),
                                    if (segment.category.trim().isNotEmpty)
                                      'category': segment.category.trim(),
                                  },
                                );
                            if (!context.mounted) return;
                            SemanticsService.sendAnnouncement(
                              View.of(context),
                              copy.radioFavoriteAnnouncement(
                                showTitle: title,
                                added: !isFavorite,
                              ),
                              Directionality.of(context),
                            );
                          }
                        : null,
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 26,
                      color: isFavorite
                          ? context.udaan.primary
                          : context.udaan.primaryGlow,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _SegmentThumbnail extends ConsumerWidget {
  const _SegmentThumbnail({
    required this.imageUrl,
    required this.title,
  });

  final String imageUrl;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolved = resolveWpMediaUrl(
      imageUrl,
      apiBaseUrl: ref.watch(apiBaseUrlProvider),
      siteUrl: ref.watch(remoteConfigProvider)?.siteUrl,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 72,
        height: 72,
        child: resolved.isNotEmpty
            ? Semantics(
                label: title,
                image: true,
                child: CachedNetworkImage(
                  key: ValueKey(resolved),
                  imageUrl: resolved,
                  fit: BoxFit.cover,
                  memCacheHeight: 144,
                  placeholder: (_, _) => const _ThumbnailPlaceholder(),
                  errorWidget: (_, _, _) => const _ThumbnailPlaceholder(),
                ),
              )
            : const _ThumbnailPlaceholder(),
      ),
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.udaan.surfaceContainerHigh,
      child: Center(
        child: Icon(
          Icons.mic_none_outlined,
          size: 32,
          color: context.udaan.primaryGlow,
        ),
      ),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  const _ChipLabel({
    required this.text,
    required this.color,
    required this.textColor,
    this.icon,
  });

  final String text;
  final Color color;
  final Color textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.udaan.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleLoading extends ConsumerWidget {
  const _ScheduleLoading();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = ref.watch(appCopyProvider);
    return Semantics(
      label: copy.semanticsLoading,
      liveRegion: true,
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(color: context.udaan.primaryGlow),
        ),
      ),
    );
  }
}

class _ScheduleError extends ConsumerWidget {
  const _ScheduleError();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = ref.watch(appCopyProvider);
    return Padding(
      padding: const EdgeInsets.all(BrandTokens.screenPadding),
      child: Center(
        child: Semantics(
          label: copy.radioScheduleFailed,
          liveRegion: true,
          child: ExcludeSemantics(
            child: Text(            copy.radioScheduleFailed,
            textAlign: TextAlign.center,
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.udaan.onSurfaceVariant,
            ),
            ),
          ),
        ),
      ),
    );
  }
}
