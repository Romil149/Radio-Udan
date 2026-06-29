import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/event_summary.dart';
import '../../core/network/dio_exception_mapper.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/udaan_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/main_tab_app_bar.dart';
import 'event_registration_screen.dart';
import 'widgets/event_card.dart';

final eventsProvider = FutureProvider<List<EventSummary>>((ref) async {
  final items =
      await ref.read(radioudaanApiProvider).listEvents(status: 'all');
  return [...items]..sort((a, b) {
      if (a.isRegistrationOpen == b.isRegistrationOpen) return 0;
      return a.isRegistrationOpen ? -1 : 1;
    });
});

/// Events list — open and closed — with in-app registration when open.
class EventsTab extends ConsumerWidget {
  const EventsTab({super.key});

  String _bannerUrl(WidgetRef ref, EventSummary event) {
    return resolveEventBannerUrl(
      event,
      apiBaseUrl: ref.watch(apiBaseUrlProvider),
      siteUrl: ref.watch(remoteConfigProvider)?.siteUrl,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = ref.watch(appCopyProvider);
    final events = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: MainTabAppBar(title: copy.tabEvents),
      body: SafeArea(
        child: events.when(
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                message: copy.eventsEmpty,
                icon: Icons.event_busy_outlined,
              );
            }
            return Semantics(
              label: copy.tabEvents,
              child: RefreshIndicator(
                color: context.udaan.primary,
                backgroundColor: context.udaan.surfaceContainer,
                onRefresh: () async {
                  ref.invalidate(eventsProvider);
                  await ref.read(eventsProvider.future);
                },
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        BrandTokens.screenPadding,
                        8,
                        BrandTokens.screenPadding,
                        16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            label: copy.eventsPageTitle,
                            child: ExcludeSemantics(
                              child: Text(
                                copy.eventsPageTitle,
                                style: GoogleFonts.atkinsonHyperlegible(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: context.udaan.primaryGlow,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Semantics(
                            label: copy.eventsPageIntro,
                            child: ExcludeSemantics(
                              child: Text(
                                copy.eventsPageIntro,
                                style: GoogleFonts.atkinsonHyperlegible(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: context.udaan.onSurfaceVariant,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BrandTokens.screenPadding,
                      ),
                      child: Column(
                        children: [
                          for (final event in items) ...[
                            EventCard(
                              copy: copy,
                              event: event,
                              bannerUrl: _bannerUrl(ref, event),
                              onRegister: event.isRegistrationOpen
                                  ? () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              EventRegistrationScreen(
                                            eventId: event.eventId,
                                            title: event.title,
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => Center(
            child: Semantics(
              label: copy.eventsLoading,
              liveRegion: true,
              child: CircularProgressIndicator(color: context.udaan.primary),
            ),
          ),
          error: (error, _) => EmptyState(
            message: parseApiError(error).message,
            icon: Icons.error_outline,
            actionLabel: copy.retry,
            onAction: () => ref.invalidate(eventsProvider),
          ),
        ),
      ),
    );
  }
}
