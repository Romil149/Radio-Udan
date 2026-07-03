import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/live_radio_config.dart';
import '../../core/models/radio_schedule.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/wp_media_url.dart';
import 'radio_schedule_provider.dart';
import 'radio_stream_metadata.dart';

/// Hero + lock-screen copy: schedule when on-air, WP defaults between shows,
/// stream metadata when playing inside a slot.
class LiveNowPlaying {
  const LiveNowPlaying({
    required this.title,
    required this.hostsLine,
    required this.imageUrl,
    required this.showId,
    required this.isOnAir,
    required this.isFromStream,
  });

  final String title;
  final String hostsLine;
  final String imageUrl;
  final String showId;
  final bool isOnAir;
  final bool isFromStream;

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
  required LiveRadioConfig adminDefaults,
  required AppCopy copy,
  required String? icyTitle,
  required bool audiblePlayback,
  RadioScheduleSegment? scheduledOnAir,
  DateTime? now,
}) {
  final defaults = adminDefaults;
  final defaultHosts = defaults.showSubtitle.trim().isNotEmpty
      ? formatRadioHostsLine(defaults.showSubtitle, copy)
      : '';

  final inScheduledSlot =
      scheduledOnAir != null && scheduledOnAir.isOnAirNow(now);

  if (!inScheduledSlot) {
    return LiveNowPlaying(
      title: defaults.showTitle,
      hostsLine: defaultHosts,
      imageUrl: defaults.heroImageUrl,
      showId: '',
      isOnAir: false,
      isFromStream: false,
    );
  }

  final slot = scheduledOnAir;
  final scheduleHosts = slot.hasHosts
      ? formatRadioHostsLine(slot.hosts, copy)
      : defaultHosts;
  final scheduleImage =
      slot.hasImage ? slot.imageUrl : defaults.heroImageUrl;

  if (!audiblePlayback) {
    return LiveNowPlaying(
      title: slot.title,
      hostsLine: scheduleHosts,
      imageUrl: scheduleImage,
      showId: slot.id,
      isOnAir: true,
      isFromStream: false,
    );
  }

  final parsed = parseRadioStreamTitle(icyTitle);
  final streamHosts = parsed?.artist != null &&
          parsed!.artist!.trim().isNotEmpty
      ? formatRadioHostsLine(parsed.artist!, copy)
      : '';

  final title = parsed?.title.trim().isNotEmpty == true
      ? parsed!.title.trim()
      : slot.title;

  final hostsLine =
      streamHosts.isNotEmpty ? streamHosts : scheduleHosts;

  return LiveNowPlaying(
    title: title,
    hostsLine: hostsLine,
    imageUrl: scheduleImage,
    showId: slot.id,
    isOnAir: true,
    isFromStream: parsed != null,
  );
}

final liveNowPlayingProvider = Provider<LiveNowPlaying>((ref) {
  final config = ref.watch(liveRadioProvider);
  final copy = ref.watch(appCopyProvider);
  final apiBase = ref.watch(apiBaseUrlProvider);
  final siteUrl = ref.watch(remoteConfigProvider)?.siteUrl;
  final icyTitle = ref.watch(radioStreamIcyTitleProvider);
  final audiblePlayback = ref.watch(radioAudiblePlaybackProvider);
  final scheduledOnAir = ref.watch(radioScheduleProvider).valueOrNull?.onAir;

  var playing = resolveLiveNowPlaying(
    adminDefaults: config.adminDefaults,
    copy: copy,
    icyTitle: icyTitle,
    audiblePlayback: audiblePlayback,
    scheduledOnAir: scheduledOnAir,
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
    isFromStream: playing.isFromStream,
  );
});
