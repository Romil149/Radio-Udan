import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_branding.dart';
import '../../core/config/app_copy_accessors.dart';
import '../../core/config/live_radio_config.dart';
import '../../core/models/radio_schedule.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/wp_media_url.dart';
import 'radio_schedule_sheet.dart';

/// Hero + lock-screen copy resolved from the program schedule (radio-shows CPT).
class LiveNowPlaying {
  const LiveNowPlaying({
    required this.title,
    required this.hostsLine,
    required this.imageUrl,
    required this.showId,
    required this.isFromSchedule,
    this.segment,
  });

  final String title;
  final String hostsLine;
  final String imageUrl;
  final String showId;
  final bool isFromSchedule;
  final RadioScheduleSegment? segment;

  bool get hasShowId => showId.isNotEmpty;
}

/// Prefix RJ line as "with …" when the API returns bare host names.
String formatRadioHostsLine(String hosts, AppCopy copy) {
  final trimmed = hosts.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.toLowerCase().startsWith('with ')) return trimmed;
  return '${copy.radioWithHostsPrefix}$trimmed';
}

LiveNowPlaying resolveLiveNowPlaying({
  required RadioScheduleResponse? schedule,
  required LiveRadioConfig configFallback,
  required bool scheduleLoaded,
}) {
  final onAir = schedule?.onAir;
  if (onAir != null && onAir.title.trim().isNotEmpty) {
    return _fromSegment(onAir, configFallback, isFromSchedule: true);
  }

  final next = schedule?.next;
  if (scheduleLoaded && next != null && next.title.trim().isNotEmpty) {
    return _fromSegment(next, configFallback, isFromSchedule: true);
  }

  return LiveNowPlaying(
    title: configFallback.showTitle,
    hostsLine: configFallback.showSubtitle,
    imageUrl: configFallback.heroImageUrl,
    showId: '',
    isFromSchedule: false,
    segment: null,
  );
}

LiveNowPlaying _fromSegment(
  RadioScheduleSegment segment,
  LiveRadioConfig configFallback, {
  required bool isFromSchedule,
}) {
  final image = segment.imageUrl.trim().isNotEmpty
      ? segment.imageUrl
      : configFallback.heroImageUrl;
  return LiveNowPlaying(
    title: segment.title,
    hostsLine: formatRadioHostsLine(segment.hosts, AppCopy.fallback),
    imageUrl: image,
    showId: segment.id,
    isFromSchedule: isFromSchedule,
    segment: segment,
  );
}

final liveNowPlayingProvider = Provider<LiveNowPlaying>((ref) {
  final config = ref.watch(liveRadioProvider);
  final scheduleAsync = ref.watch(radioScheduleProvider);
  final apiBase = ref.watch(apiBaseUrlProvider);
  final siteUrl = ref.watch(remoteConfigProvider)?.siteUrl;

  final playing = resolveLiveNowPlaying(
    schedule: scheduleAsync.valueOrNull,
    configFallback: config,
    scheduleLoaded: scheduleAsync.hasValue,
  );

  final imageUrl = resolveWpMediaUrl(
    playing.imageUrl,
    apiBaseUrl: apiBase,
    siteUrl: siteUrl,
  );

  if (imageUrl == playing.imageUrl) return playing;

  return LiveNowPlaying(
    title: playing.title,
    hostsLine: playing.hostsLine,
    imageUrl: imageUrl,
    showId: playing.showId,
    isFromSchedule: playing.isFromSchedule,
    segment: playing.segment,
  );
});
