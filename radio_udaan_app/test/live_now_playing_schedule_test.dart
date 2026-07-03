import 'package:flutter_test/flutter_test.dart';
import 'package:radio_udaan_app/core/config/app_branding.dart';
import 'package:radio_udaan_app/core/config/app_copy_accessors.dart';
import 'package:radio_udaan_app/core/config/live_radio_config.dart';
import 'package:radio_udaan_app/core/models/radio_schedule.dart';
import 'package:radio_udaan_app/features/radio/live_now_playing.dart';

void main() {
  final copy = AppCopy.fallback;
  final defaults = LiveRadioConfig.fallback;

  group('resolveLiveNowPlaying schedule windows', () {
    test('between shows uses WP admin defaults', () {
      final pastSlot = RadioScheduleSegment(
        id: '1',
        title: 'Techcity',
        subtitle: '',
        hosts: 'RJ One',
        imageUrl: 'https://example.com/show.jpg',
        broadcastTime: '4:00 PM',
        category: '',
        startsAt: DateTime.now().subtract(const Duration(hours: 2)),
        endsAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      final hero = resolveLiveNowPlaying(
        adminDefaults: defaults,
        copy: copy,
        icyTitle: null,
        audiblePlayback: false,
        scheduledOnAir: pastSlot,
      );

      expect(hero.title, defaults.showTitle);
      expect(hero.isOnAir, isFalse);
      expect(hero.showId, isEmpty);
    });

    test('during scheduled slot uses show title and id', () {
      final now = DateTime.now();
      final onAir = RadioScheduleSegment(
        id: '42',
        title: 'Dil Se Dil Tak',
        subtitle: '',
        hosts: 'Priya',
        imageUrl: '',
        broadcastTime: '5:00 PM',
        category: '',
        startsAt: now.subtract(const Duration(minutes: 10)),
        endsAt: now.add(const Duration(minutes: 50)),
      );

      final hero = resolveLiveNowPlaying(
        adminDefaults: defaults,
        copy: copy,
        icyTitle: null,
        audiblePlayback: false,
        scheduledOnAir: onAir,
        now: now,
      );

      expect(hero.title, 'Dil Se Dil Tak');
      expect(hero.showId, '42');
      expect(hero.isOnAir, isTrue);
    });
  });
}
