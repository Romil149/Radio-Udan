import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';

/// Relative created-at label for notification cards (e.g. "2 hours ago").
String formatNotificationRelativeTime(String? raw, AppCopy copy) {
  final parsed = DateTime.tryParse(raw ?? '');
  if (parsed == null) return '';

  final now = DateTime.now();
  final local = parsed.toLocal();
  final diff = now.difference(local);

  if (diff.isNegative || diff.inMinutes < 1) {
    return copy.notificationTimeJustNow;
  }
  if (diff.inHours < 1) {
    final minutes = diff.inMinutes;
    return minutes == 1
        ? copy.notificationTimeMinuteAgo
        : copy.notificationTimeMinutesAgo(minutes);
  }
  if (diff.inHours < 24) {
    final hours = diff.inHours;
    return hours == 1
        ? copy.notificationTimeHourAgo
        : copy.notificationTimeHoursAgo(hours);
  }
  if (diff.inDays == 1) {
    return copy.notificationTimeYesterday;
  }
  if (diff.inDays < 7) {
    return copy.notificationTimeDaysAgo(diff.inDays);
  }

  return DateFormat.yMMMd().add_jm().format(local);
}
