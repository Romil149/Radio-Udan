import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/bootstrap/app_bootstrap.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/udaan_colors.dart';
import 'widgets/splash_body.dart';

/// Cold start: load config, restore session, then route to home or login.
class BootstrapScreen extends ConsumerStatefulWidget {
  const BootstrapScreen({super.key});

  @override
  ConsumerState<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends ConsumerState<BootstrapScreen> {
  bool _navigated = false;
  final DateTime _splashStarted = DateTime.now();

  /// Minimum time on splash so branding is visible (Stitch layout).
  static const Duration _minSplash = Duration(milliseconds: 1800);

  void _navigate(BootstrapResult result) {
    if (_navigated) return;
    final elapsed = DateTime.now().difference(_splashStarted);
    final wait = _minSplash - elapsed;
    if (wait > Duration.zero) {
      Future<void>.delayed(wait, () {
        if (!mounted) return;
        _completeNavigation(result);
      });
      return;
    }
    _completeNavigation(result);
  }

  void _completeNavigation(BootstrapResult result) {
    if (_navigated) return;
    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (result.isLoggedIn) {
        final pending = ref.read(pendingEventDeepLinkProvider);
        context.go(pending != null ? '/event/$pending' : '/');
      } else {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bootstrap = ref.watch(bootstrapProvider);
    final branding = ref.watch(appBrandingProvider);
    final copy = ref.watch(appCopyProvider);
    ref.listen(bootstrapProvider, (prev, next) {
      next.whenData(_navigate);
    });

    return Scaffold(
      backgroundColor: UdaanColors.background,
      body: bootstrap.when(
        data: (result) {
          _navigate(result);
          // Keep splash visible until navigation completes (avoids black flash).
          if (_navigated) return const SizedBox.shrink();
          return SplashBody(
            branding: branding,
            copy: copy,
            statusMessage: copy.bootstrapLoading,
            showLoading: true,
          );
        },
        loading: () => SplashBody(
          branding: branding,
          copy: copy,
          statusMessage: copy.bootstrapLoading,
          showLoading: true,
        ),
        error: (error, _) => SplashBody(
          branding: branding,
          copy: copy,
          statusMessage: copy.bootstrapOffline,
          showLoading: false,
          errorDetail: error.toString(),
          onRetry: () {
            _navigated = false;
            ref.invalidate(bootstrapProvider);
          },
        ),
      ),
    );
  }
}
