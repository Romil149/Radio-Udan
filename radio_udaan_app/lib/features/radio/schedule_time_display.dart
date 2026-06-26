import 'package:intl/intl.dart';

import '../../core/config/app_branding.dart';
import '../../core/config/app_copy_accessors.dart';
import '../../core/models/radio_schedule.dart';

/// Schedule wall-clock helpers — station time from API, local time on device.
abstract final class ScheduleTimeDisplay {
  /// Offset embedded in API `starts_at` (station clock).
  static Duration stationOffsetFromSchedule(RadioScheduleResponse schedule) {
    for (final segment in _allSegments(schedule)) {
      final starts = segment.startsAt;
      if (starts != null) {
        return starts.timeZoneOffset;
      }
    }
    return const Duration(hours: 5, minutes: 30);
  }

  static bool deviceDiffersFromStation(Duration stationOffset) {
    return DateTime.now().timeZoneOffset != stationOffset;
  }

  /// Visible time chip: station only in IST; dual label when user TZ differs.
  static String label({
    required RadioScheduleSegment segment,
    required Duration stationOffset,
    required AppCopy copy,
    DateFormat? timeFormat,
  }) {
    final fmt = timeFormat ?? DateFormat('h:mm a');
    final stationWall = segment.broadcastTime.isNotEmpty
        ? segment.broadcastTime
        : _formatWallClock(segment.startsAt, stationOffset, fmt);

    if (stationWall.isEmpty) return '';

    if (!deviceDiffersFromStation(stationOffset)) {
      return stationWall;
    }

    final starts = segment.startsAt;
    if (starts == null) {
      return copy.radioScheduleStationTimeLabel(stationWall);
    }

    final localWall = fmt.format(starts.toLocal());
    return copy.radioScheduleDualTimeLabel(
      stationTime: stationWall,
      localTime: localWall,
    );
  }

  static Iterable<RadioScheduleSegment> _allSegments(
    RadioScheduleResponse schedule,
  ) sync* {
    if (schedule.onAir != null) yield schedule.onAir!;
    if (schedule.next != null) yield schedule.next!;
    for (final day in schedule.days) {
      yield* day.segments;
    }
  }

  static String _formatWallClock(
    DateTime? instant,
    Duration stationOffset,
    DateFormat fmt,
  ) {
    if (instant == null) return '';
    final utc = instant.toUtc();
    final shifted = utc.add(stationOffset);
    return fmt.format(
      DateTime(
        shifted.year,
        shifted.month,
        shifted.day,
        shifted.hour,
        shifted.minute,
      ),
    );
  }
}
