import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config/app_branding.dart';
import '../../../core/config/app_copy_accessors.dart';
import '../../../core/models/event_summary.dart';
import '../../../core/theme/brand_tokens.dart';
import '../../../core/theme/udaan_colors.dart';
import '../../../core/utils/wp_media_url.dart';
import '../event_formatters.dart';

const double _eventMinTapTarget = 56;

/// Stitch-style event card: banner, type badge, schedule, summary, register CTA.
/// Screen readers focus one control: "Register For {title}" → opens registration.
class EventCard extends StatelessWidget {
  const EventCard({
    required this.copy,
    required this.event,
    required this.bannerUrl,
    this.onRegister,
    super.key,
  });

  final AppCopy copy;
  final EventSummary event;
  final String bannerUrl;
  final VoidCallback? onRegister;

  Color _badgeBackground(BuildContext context) {
    switch (event.eventType) {
      case EventType.workshop:
        return context.udaan.secondary;
      case EventType.liveStream:
        return context.udaan.primary;
      case EventType.other:
        return context.udaan.surfaceContainerHigh;
    }
  }

  Color _badgeForeground(BuildContext context) {
    switch (event.eventType) {
      case EventType.workshop:
        return context.udaan.onPrimary;
      case EventType.liveStream:
        return context.udaan.onPrimary;
      case EventType.other:
        return context.udaan.onBackground;
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = event.startAt != null
        ? formatEventScheduleLine(event.startAt!)
        : '';
    final summary = event.summary?.trim() ?? '';

    final registrationOpen = event.isRegistrationOpen;
    final semanticsLabel = registrationOpen
        ? copy.eventRegisterForSemantics(event.title)
        : copy.eventRegistrationClosedSemantics(event.title);

    return Semantics(
      button: registrationOpen,
      enabled: registrationOpen,
      label: semanticsLabel,
      onTap: registrationOpen ? onRegister : null,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: registrationOpen ? onRegister : null,
            borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
            child: Container(
              decoration: BoxDecoration(
                color: context.udaan.surfaceContainer,
                borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
                border: Border.all(color: context.udaan.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _EventBanner(
                    title: event.title,
                    bannerUrl: bannerUrl,
                    badgeLabel: event.hasBadge ? event.badgeLabel : null,
                    badgeBackground: _badgeBackground(context),
                    badgeForeground: _badgeForeground(context),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (schedule.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: context.udaan.primaryGlow,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  schedule,
                                  style: GoogleFonts.atkinsonHyperlegible(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                    color: context.udaan.primaryGlow,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                        Text(
                          event.title,
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: context.udaan.onBackground,
                          ),
                        ),
                        if (summary.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            summary,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: context.udaan.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        _RegisterButton(
                          copy: copy,
                          registrationOpen: registrationOpen,
                          onRegister: onRegister,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterButton extends StatelessWidget {
  const _RegisterButton({
    required this.copy,
    required this.registrationOpen,
    required this.onRegister,
  });

  final AppCopy copy;
  final bool registrationOpen;
  final VoidCallback? onRegister;

  @override
  Widget build(BuildContext context) {
    final label = registrationOpen
        ? copy.eventsRegisterNow
        : copy.eventsRegistrationClosed;

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: registrationOpen ? onRegister : null,
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, _eventMinTapTarget),
          backgroundColor: registrationOpen
              ? context.udaan.primary
              : context.udaan.surfaceContainerHigh,
          foregroundColor: registrationOpen
              ? context.udaan.onPrimary
              : context.udaan.onSurfaceMuted,
          disabledBackgroundColor: context.udaan.surfaceContainerHigh,
          disabledForegroundColor: context.udaan.onSurfaceMuted,
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
            CachedNetworkImage(
              imageUrl: bannerUrl,
              fit: BoxFit.cover,
              memCacheHeight: 360,
              placeholder: (_, _) => const _BannerPlaceholder(),
              errorWidget: (_, _, _) => const _BannerPlaceholder(),
            )
          else
            const _BannerPlaceholder(),
          if (badgeLabel != null && badgeLabel!.isNotEmpty)
            Positioned(
              left: 12,
              top: 12,
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
      color: context.udaan.surfaceContainerHigh,
      child: Center(
        child: Icon(
          Icons.event_outlined,
          size: 48,
          color: context.udaan.onSurfaceMuted.withValues(alpha: 0.7),
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
