import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_branding.dart';
import '../../core/config/app_copy_accessors.dart';
import '../../core/config/live_radio_config.dart';
import '../../core/models/azuracast_now_playing.dart';
import '../../core/models/radio_schedule.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/wp_media_url.dart';
import 'azuracast_now_playing_provider.dart';
import 'radio_schedule_provider.dart';
import 'radio_stream_metadata.dart';

/// Hero + lock-screen copy: AzuraCast (direct API) + ICY when playing.
class LiveNowPlaying {
  const LiveNowPlaying({
    required this.title,
    required this.hostsLine,
    required this.imageUrl,
    required this.showId,
    required this.isOnAir,
    required this.isFromStream,
    required this.playlist,
  });

  final String title;
  final String hostsLine;
  final String imageUrl;
  final String showId;
  final bool isOnAir;
  final bool isFromStream;
  final String playlist;

  bool get hasShowId => showId.isNotEmpty;
}

/// Prefix RJ / artist line as "with …" when the API returns bare names.
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
  required LiveRadioConfig liveRadio,
  required AppCopy copy,
  required AppBranding branding,
  required AzuraCastNowPlaying? azuracast,
  required String? icyTitle,
  required bool audiblePlayback,
  RadioScheduleSegment? scheduledOnAir,
  DateTime? now,
}) {
  final inScheduledSlot =
      scheduledOnAir != null && scheduledOnAir.isOnAirNow(now);
  final showId = inScheduledSlot ? scheduledOnAir.id : liveRadio.scheduledShowId;

  var title = azuracast?.title.trim() ?? '';
  if (title.isEmpty) {
    title = '${branding.appName} Live';
  }

  var hostsLine = azuracast != null
      ? formatRadioHostsLine(azuracast.artist, copy)
      : '';

  var imageUrl = azuracast?.artUrl.trim() ?? '';
  if (imageUrl.isEmpty) {
    imageUrl = liveRadio.heroImageUrl.trim();
  }

  var playlist = azuracast?.playlist.trim() ?? '';
  var isFromStream = azuracast != null;

  if (audiblePlayback) {
    final parsed = parseRadioStreamTitle(icyTitle);
    if (parsed != null) {
      if (parsed.title.trim().isNotEmpty) {
        title = parsed.title.trim();
      }
      final streamHosts = parsed.artist != null &&
              parsed.artist!.trim().isNotEmpty
          ? formatRadioHostsLine(parsed.artist!, copy)
          : '';
      if (streamHosts.isNotEmpty) {
        hostsLine = streamHosts;
      }
      isFromStream = true;
    }
  }

  return LiveNowPlaying(
    title: title,
    hostsLine: hostsLine,
    imageUrl: imageUrl,
    showId: showId,
    isOnAir: (azuracast?.isOnline ?? true) &&
        (inScheduledSlot || liveRadio.fromSchedule || azuracast != null),
    isFromStream: isFromStream,
    playlist: playlist,
  );
}

final liveNowPlayingProvider = Provider<LiveNowPlaying>((ref) {
  final liveRadio = ref.watch(liveRadioProvider);
  final copy = ref.watch(appCopyProvider);
  final branding = ref.watch(appBrandingProvider);
  final apiBase = ref.watch(apiBaseUrlProvider);
  final siteUrl = ref.watch(remoteConfigProvider)?.siteUrl;
  final azuracast = ref.watch(azuracastNowPlayingProvider);
  final icyTitle = ref.watch(radioStreamIcyTitleProvider);
  final audiblePlayback = ref.watch(radioAudiblePlaybackProvider);
  final scheduledOnAir = ref.watch(radioScheduleProvider).valueOrNull?.onAir;

  var playing = resolveLiveNowPlaying(
    liveRadio: liveRadio,
    copy: copy,
    branding: branding,
    azuracast: azuracast,
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
    playlist: playing.playlist,
  );
});

/// Next track line for the upcoming card (AzuraCast `playing_next`).
final azuracastUpcomingProvider = Provider<({String title, String subtitle})?>((ref) {
  final azura = ref.watch(azuracastNowPlayingProvider);
  if (azura == null || !azura.hasNext) return null;

  final parts = <String>[
    if (azura.nextPlaylist.trim().isNotEmpty) azura.nextPlaylist.trim(),
  ];
  return (
    title: azura.nextTitle.trim(),
    subtitle: parts.join(' • '),
  );
});
