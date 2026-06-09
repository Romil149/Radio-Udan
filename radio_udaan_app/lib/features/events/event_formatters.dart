import 'package:intl/intl.dart';

/// Formats event start time for cards (mockup: OCTOBER 24, 2024 • 6:00 PM IST).
String formatEventScheduleLine(DateTime startAt) {
  final local = startAt.toLocal();
  final date = DateFormat('MMMM d, yyyy').format(local).toUpperCase();
  final time = DateFormat('h:mm a').format(local).toUpperCase();
  return '$date • $time IST';
}
