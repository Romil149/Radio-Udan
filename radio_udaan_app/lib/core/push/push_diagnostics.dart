import 'package:flutter/foundation.dart';

/// Severity of a push diagnostics entry — drives colour + tag in the log view.
enum PushLogLevel { info, ok, warn, error }

/// A single timestamped step in the push registration trail.
@immutable
class PushLogEntry {
  PushLogEntry(this.message, {this.level = PushLogLevel.info})
      : time = DateTime.now();

  final DateTime time;
  final String message;
  final PushLogLevel level;

  String get _tag => switch (level) {
        PushLogLevel.info => 'INFO',
        PushLogLevel.ok => ' OK ',
        PushLogLevel.warn => 'WARN',
        PushLogLevel.error => 'FAIL',
      };

  /// Copy-friendly single line, e.g. `[19:07:04.512] OK  Permission granted`.
  String get formatted {
    final iso = time.toIso8601String();
    final clock = iso.length >= 23 ? iso.substring(11, 23) : iso;
    return '[$clock] $_tag  $message';
  }
}

/// In-memory diagnostics trail for the push registration flow.
///
/// `debugPrint` is invisible on release / TestFlight builds, so every push
/// step is also recorded here and surfaced on the Push Diagnostics screen.
/// This lets us see exactly where registration succeeds or fails on a real
/// device with no cable attached.
class PushDiagnostics {
  PushDiagnostics._();

  static final PushDiagnostics instance = PushDiagnostics._();

  static const int _maxEntries = 300;

  /// Live list of steps; the diagnostics screen listens for updates.
  final ValueNotifier<List<PushLogEntry>> entries =
      ValueNotifier<List<PushLogEntry>>(const <PushLogEntry>[]);

  void log(String message, {PushLogLevel level = PushLogLevel.info}) {
    final entry = PushLogEntry(message, level: level);
    final next = [...entries.value, entry];
    if (next.length > _maxEntries) {
      next.removeRange(0, next.length - _maxEntries);
    }
    entries.value = next;
    if (kDebugMode) {
      debugPrint('[push] ${entry.formatted}');
    }
  }

  void ok(String message) => log(message, level: PushLogLevel.ok);
  void warn(String message) => log(message, level: PushLogLevel.warn);
  void error(String message) => log(message, level: PushLogLevel.error);

  void clear() => entries.value = const <PushLogEntry>[];

  /// Whole trail as plain text for the Copy button / sharing.
  String asText() => entries.value.map((e) => e.formatted).join('\n');
}
