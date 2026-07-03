import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radio_udaan_app/features/radio/radio_stream_metadata.dart';

void main() {
  test('volume slider must not unmute idle metadata probe (audible flag false)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(radioAudiblePlaybackProvider), isFalse);
    // RadioPlayerNotifier.applyVolumePreference skips setVolume when this is false.
  });
}
