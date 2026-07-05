import 'package:flutter_test/flutter_test.dart';
import 'package:radio_udaan_app/core/config/app_branding.dart';
import 'package:radio_udaan_app/core/config/app_copy_accessors.dart';
import 'package:radio_udaan_app/core/config/live_radio_config.dart';
import 'package:radio_udaan_app/core/models/azuracast_now_playing.dart';
import 'package:radio_udaan_app/core/models/radio_schedule.dart';
import 'package:radio_udaan_app/features/radio/live_now_playing.dart';

void main() {
  final copy = AppCopy.fallback;
  final branding = AppBranding.defaults;

  const liveRadio = LiveRadioConfig(
    heroImageUrl: 'https://example.com/fallback.jpg',
    fromSchedule: true,
    scheduledShowId: '42',
    whatsappUrl: '',
    whatsappLabel: '',
    shareLabel: 'Share',
    shareText: '',
    showWhatsapp: false,
    showShare: true,
    showVolume: true,
    menuAction: 'more',
    profileAction: 'more',
  );

  const azuracast = AzuraCastNowPlaying(
    title: 'Mausam Mausam Lovely',
    artist: 'Anwar & Sulakshana Pandit',
    artUrl: 'https://stream.radioudaan.com/art.jpg',
    playlist: 'evergreen',
    isLive: false,
    streamerName: '',
    isOnline: true,
  );

  group('resolveLiveNowPlaying', () {
    test('uses AzuraCast title and artist before play', () {
      final hero = resolveLiveNowPlaying(
        liveRadio: liveRadio,
        copy: copy,
        branding: branding,
        azuracast: azuracast,
        icyTitle: null,
        audiblePlayback: false,
        scheduledOnAir: null,
      );

      expect(hero.title, 'Mausam Mausam Lovely');
      expect(hero.hostsLine, contains('Anwar'));
      expect(hero.isFromStream, isTrue);
      expect(hero.showId, '42');
      expect(hero.imageUrl, azuracast.artUrl);
    });

    test('ICY metadata overrides AzuraCast while playing', () {
      final hero = resolveLiveNowPlaying(
        liveRadio: liveRadio,
        copy: copy,
        branding: branding,
        azuracast: azuracast,
        icyTitle: 'New Artist - New Song',
        audiblePlayback: true,
        scheduledOnAir: null,
      );

      expect(hero.title, 'New Song');
      expect(hero.hostsLine, contains('New Artist'));
    });

    test('falls back to WP hero when AzuraCast has no art', () {
      const noArt = AzuraCastNowPlaying(
        title: 'Track',
        artist: '',
        artUrl: '',
        playlist: '',
        isLive: false,
        streamerName: '',
        isOnline: true,
      );

      final hero = resolveLiveNowPlaying(
        liveRadio: liveRadio,
        copy: copy,
        branding: branding,
        azuracast: noArt,
        icyTitle: null,
        audiblePlayback: false,
        scheduledOnAir: null,
      );

      expect(hero.imageUrl, liveRadio.heroImageUrl);
    });

    test('schedule slot sets isOnAir and show id', () {
      final now = DateTime.now();
      final onAir = RadioScheduleSegment(
        id: '99',
        title: 'Morning Show',
        subtitle: '',
        hosts: 'RJ One',
        imageUrl: '',
        broadcastTime: '5:00 PM',
        category: '',
        startsAt: now.subtract(const Duration(minutes: 10)),
        endsAt: now.add(const Duration(minutes: 50)),
      );

      final hero = resolveLiveNowPlaying(
        liveRadio: liveRadio,
        copy: copy,
        branding: branding,
        azuracast: azuracast,
        icyTitle: null,
        audiblePlayback: false,
        scheduledOnAir: onAir,
        now: now,
      );

      expect(hero.isOnAir, isTrue);
      expect(hero.showId, '99');
      expect(hero.title, 'Mausam Mausam Lovely');
    });
  });
}
