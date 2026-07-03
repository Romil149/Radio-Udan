import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Latest `StreamTitle` from the live MP3 (Shoutcast / Icecast ICY metadata).
final radioStreamIcyTitleProvider = StateProvider<String?>((ref) => null);

/// True when the user started audible playback (not silent metadata probe).
final radioAudiblePlaybackProvider = StateProvider<bool>((ref) => false);

/// Parsed ICY `StreamTitle` (often `Artist - Track` or show name).
class RadioStreamTitle {
  const RadioStreamTitle({required this.title, this.artist});

  final String title;
  final String? artist;
}

RadioStreamTitle? parseRadioStreamTitle(String? raw) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) return null;

  final dash = text.indexOf(' - ');
  if (dash > 0) {
    final artist = text.substring(0, dash).trim();
    final title = text.substring(dash + 3).trim();
    if (title.isNotEmpty) {
      return RadioStreamTitle(
        title: title,
        artist: artist.isNotEmpty ? artist : null,
      );
    }
  }

  return RadioStreamTitle(title: text);
}
