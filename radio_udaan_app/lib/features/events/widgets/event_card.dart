import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/models/event_summary.dart';
import '../../../core/theme/brand_tokens.dart';
import '../../../core/theme/udaan_colors.dart';
import '../../../core/utils/wp_media_url.dart';
import '../event_formatters.dart';

const double _eventMinTapTarget = 56;

/// Stitch-style event card: banner, type badge, schedule, summary, register CTA.
class EventCard extends StatelessWidget {
  const EventCard({
    required this.event,
    required this.bannerUrl,
    this.onRegister,
    super.key,
  });

  final EventSummary event;
  final String bannerUrl;
  final VoidCallback? onRegister;

  Color _badgeBackground() {
    switch (event.eventType) {
      case EventType.workshop:
        return UdaanColors.secondary;
      case EventType.liveStream:
        return UdaanColors.primary;
      case EventType.other:
        return UdaanColors.surfaceContainerHigh;
    }
  }

  Color _badgeForeground() {
    switch (event.eventType) {
      case EventType.workshop:
        return UdaanColors.onPrimary;
      case EventType.liveStream:
        return UdaanColors.onPrimary;
      case EventType.other:
        return UdaanColors.onBackground;
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = event.startAt != null
        ? formatEventScheduleLine(event.startAt!)
        : '';
    final summary = event.summary?.trim() ?? '';

    final registrationOpen = event.isRegistrationOpen;

    return Semantics(
      container: true,
      label: AppStrings.eventCardSemantics(
        title: event.title,
        schedule: schedule,
        badge: event.hasBadge ? event.badgeLabel : null,
        registrationOpen: registrationOpen,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: UdaanColors.surfaceContainer,
          borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
          border: Border.all(color: UdaanColors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _EventBanner(
              title: event.title,
              bannerUrl: bannerUrl,
              badgeLabel: event.hasBadge ? event.badgeLabel : null,
              badgeBackground: _badgeBackground(),
              badgeForeground: _badgeForeground(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (schedule.isNotEmpty) ...[
                    ExcludeSemantics(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: UdaanColors.primaryGlow,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              schedule,
                              style: GoogleFonts.atkinsonHyperlegible(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                                color: UdaanColors.primaryGlow,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  ExcludeSemantics(
                    child: Text(
                      event.title,
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: UdaanColors.onBackground,
                      ),
                    ),
                  ),
                  if (summary.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ExcludeSemantics(
                      child: Text(
                        summary,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: UdaanColors.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _RegisterButton(
                    eventTitle: event.title,
                    registrationOpen: registrationOpen,
                    onRegister: onRegister,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterButton extends StatelessWidget {
  const _RegisterButton({
    required this.eventTitle,
    required this.registrationOpen,
    required this.onRegister,
  });

  final String eventTitle;
  final bool registrationOpen;
  final VoidCallback? onRegister;

  @override
  Widget build(BuildContext context) {
    final label = registrationOpen
        ? AppStrings.eventsRegisterNow
        : AppStrings.eventsRegistrationClosed;
    final semanticsLabel = registrationOpen
        ? '${AppStrings.eventsRegisterNow}, $eventTitle'
        : '${AppStrings.eventsRegistrationClosed}, $eventTitle';

    return Semantics(
      button: true,
      enabled: registrationOpen,
      label: semanticsLabel,
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: registrationOpen ? onRegister : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, _eventMinTapTarget),
            backgroundColor: registrationOpen
                ? UdaanColors.primary
                : UdaanColors.surfaceContainerHigh,
            foregroundColor: registrationOpen
                ? UdaanColors.onPrimary
                : UdaanColors.onSurfaceMuted,
            disabledBackgroundColor: UdaanColors.surfaceContainerHigh,
            disabledForegroundColor: UdaanColors.onSurfaceMuted,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _EventBanner extends StatelessWidget {
  const _EventBanner({
    required this.title,
    required this.bannerUrl,
    required this.badgeLabel,
    required this.badgeBackground,
    required this.badgeForeground,
  });

  final String title;
  final String bannerUrl;
  final String? badgeLabel;
  final Color badgeBackground;
  final Color badgeForeground;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (bannerUrl.isNotEmpty)
            Semantics(
              label: '$title banner',
              image: true,
              child: CachedNetworkImage(
                imageUrl: bannerUrl,
                fit: BoxFit.cover,
                memCacheHeight: 360,
                placeholder: (_, _) => const _BannerPlaceholder(),
                errorWidget: (_, _, _) => const _BannerPlaceholder(),
              ),
            )
          else
            const _BannerPlaceholder(),
          if (badgeLabel != null && badgeLabel!.isNotEmpty)
            Positioned(
              left: 12,
              top: 12,
              child: Semantics(
                label: badgeLabel,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeLabel!,
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: badgeForeground,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BannerPlaceholder extends StatelessWidget {
  const _BannerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: UdaanColors.surfaceContainerHigh,
      child: Center(
        child: Icon(
          Icons.event_outlined,
          size: 48,
          color: UdaanColors.onSurfaceMuted.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

String resolveEventBannerUrl(
  EventSummary event, {
  required String apiBaseUrl,
  String? siteUrl,
}) {
  final raw = event.bannerImage?.url.trim() ?? '';
  if (raw.isEmpty) return '';
  return resolveWpMediaUrl(raw, apiBaseUrl: apiBaseUrl, siteUrl: siteUrl);
}
