import 'package:flutter_test/flutter_test.dart';
import 'package:radio_udaan_app/core/models/azuracast_now_playing.dart';

void main() {
  group('AzuraCastNowPlaying.fromJson', () {
    test('parses array response from /api/nowplaying', () {
      final parsed = AzuraCastNowPlaying.fromJson([
        {
          'is_online': true,
          'live': {'is_live': false, 'streamer_name': ''},
          'now_playing': {
            'playlist': 'Morning bhajan ',
            'remaining': 417,
            'song': {
              'title': 'Main nahi maakhan khayo',
              'artist': '',
              'text': ' - Main nahi maakhan khayo',
              'art':
                  'https://stream.radioudaan.com/api/station/radio_udaan/art/98ad6367',
            },
          },
          'playing_next': {
            'playlist': 'Morning bhajan ',
            'song': {
              'title': 'Radha pyari',
              'artist': '',
              'text': ' - Radha pyari',
            },
          },
        },
      ]);

      expect(parsed, isNotNull);
      expect(parsed!.title, 'Main nahi maakhan khayo');
      expect(parsed.playlist, 'Morning bhajan');
      expect(parsed.remainingSeconds, 417);
      expect(parsed.nextTitle, 'Radha pyari');
      expect(parsed.hasNext, isTrue);
    });

    test('uses DJ name when live and title empty', () {
      final parsed = AzuraCastNowPlaying.fromJson({
        'is_online': true,
        'live': {'is_live': true, 'streamer_name': 'RJ Karan'},
        'now_playing': {
          'playlist': '',
          'song': {'title': '', 'artist': '', 'text': ''},
        },
      });

      expect(parsed?.title, 'RJ Karan');
      expect(parsed?.isLive, isTrue);
    });

    test('parses artist from text field', () {
      final parsed = AzuraCastNowPlaying.fromJson({
        'is_online': true,
        'live': {'is_live': false},
        'now_playing': {
          'playlist': '',
          'song': {
            'title': 'Jai aambe Gauri',
            'artist': 'Bhajans',
            'text': 'Bhajans - Jai aambe Gauri',
          },
        },
      });

      expect(parsed?.title, 'Jai aambe Gauri');
      expect(parsed?.artist, 'Bhajans');
    });
  });
}
