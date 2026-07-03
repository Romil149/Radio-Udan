import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/live_radio_config.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/wp_media_url.dart';
import 'radio_stream_metadata.dart';

/// Hero + lock-screen copy: MP3 stream metadata when available, else WP live_radio defaults.
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
  required LiveRadioConfig configFallback,
  required AppCopy copy,
  required String? icyTitle,
  required bool audiblePlayback,
}) {
  final parsed = parseRadioStreamTitle(icyTitle);
  final title = parsed?.title.trim().isNotEmpty == true
      ? parsed!.title.trim()
      : configFallback.showTitle;

  final hostsLine = audiblePlayback && parsed?.artist != null
      ? formatRadioHostsLine(parsed!.artist!, copy)
      : '';

  return LiveNowPlaying(
    title: title,
    hostsLine: hostsLine,
    imageUrl: configFallback.heroImageUrl,
    showId: '',
    isOnAir: audiblePlayback && parsed != null,
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

  var playing = resolveLiveNowPlaying(
    configFallback: config,
    copy: copy,
    icyTitle: icyTitle,
    audiblePlayback: audiblePlayback,
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
