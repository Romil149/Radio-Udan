import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_branding.dart';
import '../../core/config/app_copy_accessors.dart';
import '../../core/config/live_radio_config.dart';
import '../../core/models/radio_schedule.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/wp_media_url.dart';
import 'radio_schedule_sheet.dart';
import 'radio_stream_metadata.dart';

/// Hero + lock-screen copy resolved from the program schedule (radio-shows CPT).
class LiveNowPlaying {
  const LiveNowPlaying({
    required this.title,
    required this.hostsLine,
    required this.imageUrl,
    required this.showId,
    required this.isOnAir,
    required this.isFromSchedule,
    this.segment,
  });

  final String title;
  final String hostsLine;
  final String imageUrl;
  final String showId;
  final bool isOnAir;
  final bool isFromSchedule;
  final RadioScheduleSegment? segment;

  bool get hasShowId => showId.isNotEmpty;
}

/// Prefix RJ line as "with …" when the API returns bare host names.
String formatRadioHostsLine(String hosts, AppCopy copy) {
  final trimmed = hosts.trim();
  if (trimmed.isEmpty) return '';

  var names = trimmed;
  final lower = names.toLowerCase();
  if (lower.startsWith('with ')) {
    names = names.substring(5).trim();
  } else if (lower.startsWith('with')) {
    names = names.substring(4).trim();
  }
  if (names.isEmpty) return '';

  final prefix = copy.radioWithHostsPrefix.trim();
  if (prefix.isEmpty) return 'with $names';
  return prefix.endsWith(' ') ? '$prefix$names' : '$prefix $names';
}

LiveNowPlaying resolveLiveNowPlaying({
  required RadioScheduleResponse? schedule,
  required LiveRadioConfig configFallback,
}) {
  final onAir = schedule?.onAir;
  if (onAir != null && onAir.title.trim().isNotEmpty) {
    return _fromSegment(onAir, configFallback, isOnAir: true);
  }

  return LiveNowPlaying(
    title: configFallback.showTitle,
    hostsLine: configFallback.showSubtitle,
    imageUrl: configFallback.heroImageUrl,
    showId: '',
    isOnAir: false,
    isFromSchedule: false,
    segment: null,
  );
}

LiveNowPlaying applyStreamMetadata({
  required LiveNowPlaying base,
  required String? icyTitle,
}) {
  final parsed = parseRadioStreamTitle(icyTitle);
  if (parsed == null) return base;

  final hosts = parsed.artist != null
      ? formatRadioHostsLine(parsed.artist!, AppCopy.fallback)
      : base.hostsLine;

  return LiveNowPlaying(
    title: parsed.title,
    hostsLine: hosts,
    imageUrl: base.imageUrl,
    showId: base.showId,
    isOnAir: base.isOnAir,
    isFromSchedule: base.isFromSchedule,
    segment: base.segment,
  );
}

LiveNowPlaying _fromSegment(
  RadioScheduleSegment segment,
  LiveRadioConfig configFallback, {
  required bool isOnAir,
}) {
  final image = segment.imageUrl.trim().isNotEmpty
      ? segment.imageUrl
      : configFallback.heroImageUrl;
  return LiveNowPlaying(
    title: segment.title,
    hostsLine: formatRadioHostsLine(segment.hosts, AppCopy.fallback),
    imageUrl: image,
    showId: segment.id,
    isOnAir: isOnAir,
    isFromSchedule: true,
    segment: segment,
  );
}

final liveNowPlayingProvider = Provider<LiveNowPlaying>((ref) {
  final config = ref.watch(liveRadioProvider);
  final scheduleAsync = ref.watch(radioScheduleProvider);
  final apiBase = ref.watch(apiBaseUrlProvider);
  final siteUrl = ref.watch(remoteConfigProvider)?.siteUrl;
  final icyTitle = ref.watch(radioStreamIcyTitleProvider);

  var playing = resolveLiveNowPlaying(
    schedule: scheduleAsync.valueOrNull,
    configFallback: config,
  );
  playing = applyStreamMetadata(
    base: playing,
    icyTitle: icyTitle,
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
    isOnAir: playing.isOnAir,
    isFromSchedule: playing.isFromSchedule,
    segment: playing.segment,
  );
});
