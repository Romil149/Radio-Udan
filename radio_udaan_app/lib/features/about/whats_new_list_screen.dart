import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/whats_new_update.dart';
import '../../core/network/dio_exception_mapper.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/udaan_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../auth/widgets/udaan_auth_widgets.dart';
import 'whats_new_detail_screen.dart';
import 'whats_new_providers.dart';

/// Combined announcements + media coverage list for the About tab.
class WhatsNewListScreen extends ConsumerWidget {
  const WhatsNewListScreen({super.key});

  void _openDetail(BuildContext context, WhatsNewListItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WhatsNewDetailScreen(
          type: item.type,
          postId: item.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = ref.watch(appCopyProvider);
    final updates = ref.watch(whatsNewListProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BrandTokens.screenPadding,
              ),
              child: UdaanAuthTopBar(
                copy: copy,
                title: copy.aboutWhatsNew,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: updates.when(
                data: (data) {
                  if (data.items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(
                          BrandTokens.screenPadding,
                        ),
                        child: Semantics(
                          label: copy.whatsNewEmpty,
                          liveRegion: true,
                          child: ExcludeSemantics(
                            child: Text(
                              copy.whatsNewEmpty,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.atkinsonHyperlegible(
                                fontSize: 16,
                                color: context.udaan.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: context.udaan.primary,
                    onRefresh: () async {
                      ref.invalidate(whatsNewListProvider);
                      await ref.read(whatsNewListProvider.future);
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(BrandTokens.screenPadding),
                      itemCount: data.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = data.items[index];
                        final label =
                            '${item.kindLabel}, ${item.title}';
                        return Semantics(
                          button: true,
                          label: label,
                          child: Material(
                            color: context.udaan.surfaceContainer,
                            borderRadius:
                                BorderRadius.circular(BrandTokens.cardRadius),
                            child: InkWell(
                              borderRadius:
                                  BorderRadius.circular(BrandTokens.cardRadius),
                              onTap: () => _openDetail(context, item),
                              child: Container(
                                constraints: const BoxConstraints(
                                  minHeight: BrandTokens.a11yMinTapTarget,
                                ),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    BrandTokens.cardRadius,
                                  ),
                                  border: Border.all(
                                    color: context.udaan.outlineVariant,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: ExcludeSemantics(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.kindLabel,
                                              style:
                                                  GoogleFonts.atkinsonHyperlegible(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: context.udaan.primaryGlow,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              item.title,
                                              style:
                                                  GoogleFonts.atkinsonHyperlegible(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w800,
                                                color: context.udaan.onBackground,
                                              ),
                                            ),
                                            if (item.summary.isNotEmpty &&
                                                item.summary != item.title) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                item.summary,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style:
                                                    GoogleFonts.atkinsonHyperlegible(
                                                  fontSize: 15,
                                                  color: context
                                                      .udaan.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                    ExcludeSemantics(
                                      child: Icon(
                                        Icons.chevron_right,
                                        color: context.udaan.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => Center(
                  child: Semantics(
                    label: copy.whatsNewDetailLoading,
                    liveRegion: true,
                    child: CircularProgressIndicator(
                      color: context.udaan.primary,
                    ),
                  ),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(BrandTokens.screenPadding),
                    child: EmptyState(
                      message: parseApiError(error).message,
                      icon: Icons.error_outline,
                      actionLabel: copy.retry,
                      onAction: () => ref.invalidate(whatsNewListProvider),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
