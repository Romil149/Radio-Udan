import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config/app_branding.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/accessibility_scope.dart';
import '../../../core/theme/udaan_colors.dart';
import '../../../core/theme/udaan_text_styles.dart';
import '../../../core/widgets/offline_brand_logo.dart';

/// Stitch splash / bootstrap loading layout (`stitch/splash_screen`).
class SplashBody extends StatelessWidget {
  const SplashBody({
    required this.branding,
    required this.statusMessage,
    required this.showLoading,
    this.errorDetail,
    this.onRetry,
    super.key,
  });

  final AppBranding branding;
  final String statusMessage;
  final bool showLoading;
  final String? errorDetail;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;
    final reduceMotion = context.reduceMotion;

    return Stack(
      fit: StackFit.expand,
      children: [
        const _SplashBackgroundGlow(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 3),
                _SplashLogo(branding: branding),
                const SizedBox(height: 28),
                _SplashTitleBlock(branding: branding),
                const Spacer(flex: 2),
                if (showLoading)
                  _SplashLoadingDots(reduceMotion: reduceMotion),
                if (showLoading) const SizedBox(height: 20),
                Semantics(
                  label: statusMessage,
                  liveRegion: true,
                  child: Text(
                    statusMessage,
                    textAlign: TextAlign.center,
                    style: udaanTextStyle(
                      context,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: palette.onBackground,
                    ),
                  ),
                ),
                if (errorDetail != null) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    label: errorDetail,
                    liveRegion: true,
                    child: Text(
                      errorDetail!,
                      textAlign: TextAlign.center,
                      style: udaanTextStyle(
                        context,
                        fontSize: 16,
                        color: palette.onSurfaceVariant.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
                if (onRetry != null) ...[
                  const SizedBox(height: 24),
                  Semantics(
                    button: true,
                    label: AppStrings.retry,
                    child: FilledButton(
                      onPressed: onRetry,
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.primary,
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(56),
                      ),
                      child: Text(
                        AppStrings.retry,
                        style: udaanTextStyle(
                          context,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
                const Spacer(flex: 3),
                const _SplashAccessibilityBadge(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SplashBackgroundGlow extends StatelessWidget {
  const _SplashBackgroundGlow();

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;
    return DecoratedBox(
      decoration: BoxDecoration(color: palette.background),
      child: Center(
        child: Container(
          width: 320,
          height: 320,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                palette.primaryGlow.withValues(alpha: 0.22),
                palette.primary.withValues(alpha: 0.06),
                Colors.transparent,
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo({required this.branding});

  final AppBranding branding;
  static const double _logoHeight = 168;

  @override
  Widget build(BuildContext context) {
    return OfflineBrandLogo(branding: branding, height: _logoHeight);
  }
}

class _SplashTitleBlock extends StatelessWidget {
  const _SplashTitleBlock({required this.branding});

  final AppBranding branding;

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            branding.appName,
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: palette.onBackground,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.splashTagline,
          textAlign: TextAlign.center,
          style: GoogleFonts.lora(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.italic,
            color: palette.onSurfaceVariant,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _SplashLoadingDots extends StatefulWidget {
  const _SplashLoadingDots({required this.reduceMotion});

  final bool reduceMotion;

  @override
  State<_SplashLoadingDots> createState() => _SplashLoadingDotsState();
}

class _SplashLoadingDotsState extends State<_SplashLoadingDots>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;

    if (widget.reduceMotion) {
      return Semantics(
        label: AppStrings.semanticsLoading,
        liveRegion: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _dot(palette: palette, size: 14, opacity: 0.85),
            const SizedBox(width: 10),
            _dot(palette: palette, size: 10, opacity: 0.55),
          ],
        ),
      );
    }

    final controller = _controller!;
    return Semantics(
      label: AppStrings.semanticsLoading,
      liveRegion: true,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final t = controller.value;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _dot(
                palette: palette,
                size: 14 + (6 * t),
                opacity: 0.55 + (0.45 * t),
              ),
              const SizedBox(width: 10),
              _dot(
                palette: palette,
                size: 8 + (6 * (1 - t)),
                opacity: 0.35 + (0.45 * (1 - t)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _dot({
    required UdaanPalette palette,
    required double size,
    required double opacity,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.primary.withValues(alpha: opacity),
      ),
    );
  }
}

class _SplashAccessibilityBadge extends StatelessWidget {
  const _SplashAccessibilityBadge();

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;
    return Semantics(
      label: AppStrings.splashA11yBadge,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: palette.surfaceContainerHigh.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: palette.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.accessibility_new,
              size: 18,
              color: palette.onSurfaceVariant.withValues(alpha: 0.95),
            ),
            const SizedBox(width: 8),
            Text(
              AppStrings.splashA11yBadge,
              style: udaanTextStyle(
                context,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: palette.onSurfaceVariant.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
