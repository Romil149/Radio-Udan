import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/whats_new_update.dart';
import '../../core/models/youtube_video.dart';
import '../../core/network/dio_exception_mapper.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/udaan_colors.dart';
import '../../core/utils/external_link.dart';
import '../../core/utils/legal_html_sanitizer.dart';
import '../../core/utils/wp_media_url.dart';
import '../../core/widgets/accessible_html_content.dart';
import '../../core/widgets/empty_state.dart';
import '../auth/widgets/udaan_auth_widgets.dart';
import '../library/library_player_screen.dart';
import 'whats_new_providers.dart';

/// In-app detail for a single what's-new or community news update.
class WhatsNewDetailScreen extends ConsumerWidget {
  const WhatsNewDetailScreen({
    required this.type,
    required this.postId,
    super.key,
  });

  final WhatsNewUpdateType type;
  final int postId;

  String? _youtubeVideoId(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return null;
    if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }
    final v = uri.queryParameters['v'];
    if (v != null && v.isNotEmpty) return v;
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = ref.watch(appCopyProvider);
    final config = ref.watch(remoteConfigProvider);
    final apiBase = ref.watch(apiBaseUrlProvider);

    final detail = type == WhatsNewUpdateType.communityNews
        ? ref.watch(whatsNewCommunityNewsDetailProvider(postId))
        : ref.watch(whatsNewAnnouncementDetailProvider(postId));

    return _scaffold(
      context,
      copy: copy,
      child: detail.when(
        data: (data) => _announcementBody(
          context,
          ref,
          copy,
          data,
          apiBase: apiBase,
          siteUrl: config?.siteUrl,
        ),
        loading: () => _loading(copy),
        error: (e, _) => _error(context, copy, e, () {
          if (type == WhatsNewUpdateType.communityNews) {
            ref.invalidate(whatsNewCommunityNewsDetailProvider(postId));
          } else {
            ref.invalidate(whatsNewAnnouncementDetailProvider(postId));
          }
        }),
      ),
    );
  }

  Widget _scaffold(
    BuildContext context, {
    required AppCopy copy,
    required Widget child,
  }) {
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
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget _loading(AppCopy copy) {
    return Center(
      child: Semantics(
        label: copy.whatsNewDetailLoading,
        liveRegion: true,
        child: const CircularProgressIndicator(),
      ),
    );
  }

  Widget _error(
    BuildContext context,
    AppCopy copy,
    Object error,
    VoidCallback onRetry,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BrandTokens.screenPadding),
        child: EmptyState(
          message: parseApiError(error).message,
          icon: Icons.error_outline,
          actionLabel: copy.retry,
          onAction: onRetry,
        ),
      ),
    );
  }

  Widget _announcementBody(
    BuildContext context,
    WidgetRef ref,
    AppCopy copy,
    WhatsNewAnnouncementDetail data, {
    required String apiBase,
    String? siteUrl,
  }) {
    final thumb = data.thumbnailUrl?.trim() ?? '';
    final youtube = data.youtubeUrl?.trim() ?? '';
    final body = data.bodyHtml?.trim() ?? '';

    return ListView(
      padding: const EdgeInsets.all(BrandTokens.screenPadding),
      children: [
        if (data.kindLabel.isNotEmpty)
          Text(
            data.kindLabel,
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: context.udaan.primaryGlow,
            ),
          ),
        if (data.category != null && data.category!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            data.category!,
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.udaan.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Semantics(
          header: true,
          label: data.title,
          child: ExcludeSemantics(
            child: Text(
              data.title,
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: context.udaan.onBackground,
              ),
            ),
          ),
        ),
        if (thumb.isNotEmpty) ...[
          const SizedBox(height: 16),
          Semantics(
            label: data.title,
            image: true,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
              child: CachedNetworkImage(
                imageUrl: resolveWpMediaUrl(thumb, apiBaseUrl: apiBase, siteUrl: siteUrl),
                fit: BoxFit.cover,
                width: double.infinity,
                memCacheHeight: 480,
              ),
            ),
          ),
        ],
        if (body.isNotEmpty) ...[
          const SizedBox(height: 20),
          AccessibleHtmlContent(
            html: sanitizeLegalPageHtml(
              rewriteWpHtmlMediaUrls(
                body,
                apiBaseUrl: apiBase,
                siteUrl: siteUrl,
              ),
            ),
          ),
        ],
        if (youtube.isNotEmpty) ...[
          const SizedBox(height: 24),
          UdaanPrimaryButton(
            label: copy.whatsNewWatchYoutube,
            icon: Icons.play_circle_outline,
            onPressed: () {
              final videoId = _youtubeVideoId(youtube);
              if (videoId != null && videoId.isNotEmpty) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LibraryPlayerScreen(
                      video: YoutubeVideo(
                        id: videoId,
                        title: data.title,
                        thumbnailUrl: thumb.isNotEmpty ? thumb : null,
                        youtubeUrl: youtube,
                      ),
                    ),
                  ),
                );
                return;
              }
              openExternalUrl(context, youtube, copy: copy);
            },
          ),
        ],
      ],
    );
  }
}
