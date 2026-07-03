import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radio_udaan_app/core/providers/app_providers.dart';
import 'package:radio_udaan_app/features/radio/radio_player_controller.dart';
import 'package:radio_udaan_app/features/radio/radio_stream_metadata.dart';

void main() {
  test('stop() sets idle immediately even when audible playback was active', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(radioAudiblePlaybackProvider.notifier).state = true;
    container.read(radioPlayerProvider.notifier).state =
        const RadioPlayerState(status: RadioPlayerStatus.playing);

    final notifier = container.read(radioPlayerProvider.notifier);
    notifier.stop();

    expect(
      container.read(radioPlayerProvider).status,
      RadioPlayerStatus.idle,
    );
    expect(container.read(radioAudiblePlaybackProvider), isFalse);
  });
}
