import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/radio_schedule.dart';
import '../../core/providers/app_providers.dart';

/// Refreshes on a timer so hero title / RJ update when the slot changes.
final radioScheduleProvider = FutureProvider<RadioScheduleResponse>((ref) async {
  final timer = Timer.periodic(const Duration(minutes: 1), (_) {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  final api = ref.read(radioudaanApiProvider);
  return api.fetchRadioSchedule(days: 2);
});
