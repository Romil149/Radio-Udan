import '../../core/config/app_branding.dart';
import '../../core/config/app_copy_accessors.dart';

/// Strips Radio Udaan channel boilerplate pasted into many YouTube descriptions.
String summarizeYoutubeDescription(String? raw) {
  var text = raw?.trim() ?? '';
  if (text.isEmpty) return '';

  const markers = [
    'Welcome to the official YouTube channel of Radio Udaan',
    'Contact Information:',
    'Stay Connected:',
    'Email us:',
    'subscribe, like, and hit the notification bell',
  ];

  for (final marker in markers) {
    final idx = text.toLowerCase().indexOf(marker.toLowerCase());
    if (idx == 0) {
      return '';
    }
    if (idx > 0) {
      text = text.substring(0, idx).trim();
    }
  }

  final paragraphs = text.split(RegExp(r'\n\s*\n'));
  for (final paragraph in paragraphs) {
    final trimmed = paragraph.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) continue;
    if (trimmed.length > 500) {
      return '${trimmed.substring(0, 497).trim()}…';
    }
    return trimmed;
  }

  return '';
}

/// Human-readable relative upload date for library cards.
String formatLibraryRelativeDate(DateTime publishedAt, AppCopy copy) {
  final now = DateTime.now();
  final local = publishedAt.toLocal();
  final diff = now.difference(local);

  if (diff.isNegative || diff.inMinutes < 1) {
    return copy.libraryUploadedJustNow;
  }
  if (diff.inHours < 1) {
    final minutes = diff.inMinutes;
    return minutes == 1
        ? copy.libraryUploadedMinuteAgo
        : copy.libraryUploadedMinutesAgo(minutes);
  }
  if (diff.inHours < 24) {
    final hours = diff.inHours;
    return hours == 1
        ? copy.libraryUploadedHourAgo
        : copy.libraryUploadedHoursAgo(hours);
  }
  if (diff.inDays < 7) {
    final days = diff.inDays;
    return days == 1
        ? copy.libraryUploadedYesterday
        : copy.libraryUploadedDaysAgo(days);
  }
  if (diff.inDays < 30) {
    final weeks = diff.inDays ~/ 7;
    return weeks == 1
        ? copy.libraryUploadedWeekAgo
        : copy.libraryUploadedWeeksAgo(weeks);
  }
  if (diff.inDays < 365) {
    final months = diff.inDays ~/ 30;
    return months <= 1
        ? copy.libraryUploadedMonthAgo
        : copy.libraryUploadedMonthsAgo(months);
  }
  final years = diff.inDays ~/ 365;
  return years == 1
      ? copy.libraryUploadedYearAgo
      : copy.libraryUploadedYearsAgo(years);
}
