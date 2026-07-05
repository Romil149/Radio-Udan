/// Parsed AzuraCast GET /api/nowplaying response (one station).
class AzuraCastNowPlaying {
  const AzuraCastNowPlaying({
    required this.title,
    required this.artist,
    required this.artUrl,
    required this.playlist,
    required this.isLive,
    required this.streamerName,
    required this.isOnline,
    this.nextTitle = '',
    this.nextPlaylist = '',
    this.remainingSeconds,
  });

  final String title;
  final String artist;
  final String artUrl;
  final String playlist;
  final bool isLive;
  final String streamerName;
  final bool isOnline;
  final String nextTitle;
  final String nextPlaylist;
  final int? remainingSeconds;

  bool get hasArt => artUrl.trim().isNotEmpty;
  bool get hasNext => nextTitle.trim().isNotEmpty;

  /// Accepts `/api/nowplaying` (array) or `/api/nowplaying/1` (object).
  static AzuraCastNowPlaying? fromJson(dynamic raw) {
    final station = _unwrapStation(raw);
    if (station == null) return null;

    final nowPlaying = station['now_playing'];
    if (nowPlaying is! Map) return null;

    final song = nowPlaying['song'];
    if (song is! Map) return null;

    final live = station['live'];
    final liveMap = live is Map ? live : const <String, dynamic>{};
    final isLive = liveMap['is_live'] == true;
    final streamer = _trim(liveMap['streamer_name']);

    final parsed = _parseSong(song);
    var title = parsed.$1;
    var artist = parsed.$2;
    final art = _trim(song['art']);
    final playlist = _trim(nowPlaying['playlist']);

    if (title.isEmpty && isLive && streamer.isNotEmpty) {
      title = streamer;
    }
    if (title.isEmpty && playlist.isNotEmpty) {
      title = playlist;
    }
    if (title.isEmpty) return null;

    final playingNext = station['playing_next'];
    String nextTitle = '';
    String nextPlaylist = '';
    if (playingNext is Map) {
      nextPlaylist = _trim(playingNext['playlist']);
      final nextSong = playingNext['song'];
      if (nextSong is Map) {
        nextTitle = _parseSong(nextSong).$1;
      }
    }

    final remaining = nowPlaying['remaining'];
    int? remainingSeconds;
    if (remaining is num) {
      remainingSeconds = remaining.round();
    }

    return AzuraCastNowPlaying(
      title: title,
      artist: artist,
      artUrl: art,
      playlist: playlist,
      isLive: isLive,
      streamerName: streamer,
      isOnline: station['is_online'] != false,
      nextTitle: nextTitle,
      nextPlaylist: nextPlaylist,
      remainingSeconds: remainingSeconds,
    );
  }

  static Map<String, dynamic>? _unwrapStation(dynamic raw) {
    if (raw is List && raw.isNotEmpty) {
      final first = raw.first;
      if (first is Map<String, dynamic>) return first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  /// Returns (title, artist) using `title`/`artist` fields and `text` fallback.
  static (String, String) _parseSong(Map<dynamic, dynamic> song) {
    var title = _trim(song['title']);
    var artist = _trim(song['artist']);
    final text = _trim(song['text']);

    if (artist.isEmpty && text.contains(' - ')) {
      final dash = text.indexOf(' - ');
      final left = text.substring(0, dash).trim();
      final right = text.substring(dash + 3).trim();
      if (right.isNotEmpty && (title.isEmpty || title == right)) {
        title = right;
      }
      if (left.isNotEmpty && left != '-') {
        artist = left;
      }
    }

    return (title, artist);
  }

  static String _trim(dynamic value) => value?.toString().trim() ?? '';
}
