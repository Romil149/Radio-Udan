import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/push/push_diagnostics.dart';
import '../../core/push/push_notification_service.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/udaan_colors.dart';
import '../../core/theme/udaan_text_styles.dart';

/// Support/debug screen that runs the push registration flow and shows every
/// step live (permission, APNs, FCM token, server call) so failures are
/// visible on real release builds without a cable. Reachable from Settings.
class PushDiagnosticsScreen extends ConsumerStatefulWidget {
  const PushDiagnosticsScreen({super.key});

  @override
  ConsumerState<PushDiagnosticsScreen> createState() =>
      _PushDiagnosticsScreenState();
}

class _PushDiagnosticsScreenState extends ConsumerState<PushDiagnosticsScreen> {
  bool _running = false;

  Future<void> _runNow() async {
    if (_running) return;
    setState(() => _running = true);
    PushDiagnostics.instance.log('— manual diagnostics run —');
    try {
      final push = ref.read(pushNotificationServiceProvider);
      final result = await push.syncForLoggedInUserDetailed();
      if (!mounted) return;
      _announce('Diagnostics finished: ${result.name}');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _copy() async {
    final text = PushDiagnostics.instance.asText();
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    _announce('Diagnostics log copied to clipboard');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Diagnostics log copied')),
    );
  }

  void _clear() {
    PushDiagnostics.instance.clear();
    _announce('Diagnostics log cleared');
  }

  void _announce(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      );
    });
  }

  Color _levelColor(PushLogLevel level, UdaanPalette palette) {
    return switch (level) {
      PushLogLevel.ok => const Color(0xFF4CAF50),
      PushLogLevel.warn => const Color(0xFFFFB300),
      PushLogLevel.error => palette.error,
      PushLogLevel.info => palette.onSurfaceVariant,
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        foregroundColor: palette.onBackground,
        title: Semantics(
          header: true,
          child: Text(
            'Push diagnostics',
            style: udaanTextStyle(
              context,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(BrandTokens.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Runs the notification registration step by step and records '
                'exactly what happens. Tap Run, then Copy log to share the '
                'result.',
                style: udaanTextStyle(
                  context,
                  fontSize: 15,
                  color: palette.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                button: true,
                label: 'Run push registration now',
                child: ExcludeSemantics(
                  child: ElevatedButton.icon(
                    onPressed: _running ? null : _runNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.primary,
                      foregroundColor: palette.onPrimary,
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    icon: _running
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: palette.onPrimary,
                            ),
                          )
                        : const Icon(Icons.play_arrow_rounded),
                    label: Text(_running ? 'Running…' : 'Run registration now'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Copy diagnostics log',
                      child: ExcludeSemantics(
                        child: OutlinedButton.icon(
                          onPressed: _copy,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 52),
                          ),
                          icon: const Icon(Icons.copy_rounded),
                          label: const Text('Copy log'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Clear diagnostics log',
                      child: ExcludeSemantics(
                        child: OutlinedButton.icon(
                          onPressed: _clear,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 52),
                          ),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Clear'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: palette.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.outlineVariant),
                  ),
                  child: ValueListenableBuilder<List<PushLogEntry>>(
                    valueListenable: PushDiagnostics.instance.entries,
                    builder: (context, entries, _) {
                      if (entries.isEmpty) {
                        return Center(
                          child: Text(
                            'No log yet. Tap “Run registration now”.',
                            style: udaanTextStyle(
                              context,
                              fontSize: 14,
                              color: palette.onSurfaceMuted,
                            ),
                          ),
                        );
                      }
                      return Semantics(
                        liveRegion: true,
                        label: 'Push diagnostics log, ${entries.length} entries',
                        child: ListView.builder(
                          reverse: true,
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final entry = entries[entries.length - 1 - index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: SelectableText(
                                entry.formatted,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12.5,
                                  height: 1.3,
                                  color: _levelColor(entry.level, palette),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
