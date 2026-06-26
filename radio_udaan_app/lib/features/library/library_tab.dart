import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/youtube_video.dart';
import '../../core/network/dio_exception_mapper.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/udaan_colors.dart';
import '../favorites/app_favorites_provider.dart';
import 'library_image_url.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/main_tab_app_bar.dart';
import 'library_playlist_videos_screen.dart';
import 'library_playlists_screen.dart';
import 'library_providers.dart';
import 'library_saved_screen.dart';
import 'widgets/library_playlist_tile.dart';
import 'widgets/library_search_field.dart';
import 'widgets/library_section_heading.dart';
import 'widgets/library_video_card.dart' show LibraryVideoCard;

const double _libraryMinTapTarget = 56;
const Duration _searchDebounce = Duration(milliseconds: 400);

/// YouTube library home: search, featured playlists, and recent uploads.
class LibraryTab extends ConsumerStatefulWidget {
  const LibraryTab({super.key});

  @override
  ConsumerState<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends ConsumerState<LibraryTab> {
  AppCopy get _copy => ref.read(appCopyProvider);

  final _searchController = TextEditingController();
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounce, () {
      if (!mounted) return;
      ref.read(librarySearchQueryProvider.notifier).state =
          _searchController.text.trim();
    });
  }

  Future<void> _refreshAll() async {
    final query = ref.read(librarySearchQueryProvider);
    ref.invalidate(featuredYoutubePlaylistsProvider);
    ref.invalidate(libraryRecentUploadsProvider);
    if (query.isNotEmpty) {
      ref.invalidate(libraryYoutubeSearchProvider(query));
    }
    await Future.wait([
      ref.read(featuredYoutubePlaylistsProvider.future),
      ref.read(libraryRecentUploadsProvider.future),
      if (query.isNotEmpty) ref.read(libraryYoutubeSearchProvider(query).future),
    ]);
  }

  String _playlistThumbnail(YoutubePlaylist playlist) =>
      playlistThumbnailFor(ref, playlist);

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(librarySearchQueryProvider);
    final isSearching = searchQuery.isNotEmpty;
    final featured = ref.watch(featuredYoutubePlaylistsProvider);
    final recent = ref.watch(libraryRecentUploadsProvider);
    final searchResults = isSearching
        ? ref.watch(libraryYoutubeSearchProvider(searchQuery))
        : null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: MainTabAppBar(title: _copy.tabLibrary),
      body: SafeArea(
        child: Semantics(
          label: _copy.tabLibrary,
          child: RefreshIndicator(
            color: UdaanColors.primary,
            backgroundColor: UdaanColors.surfaceContainer,
            onRefresh: _refreshAll,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                LibrarySearchField(controller: _searchController),
                if (!isSearching) ...[
                  _SavedEntryTile(copy: _copy),
                  const SizedBox(height: 8),
                ],
                if (isSearching) ...[
                  _SearchResultsSection(
                    results: searchResults,
                    searchEmptyLabel: _copy.librarySearchEmpty,
                    onRetry: () =>
                        ref.invalidate(libraryYoutubeSearchProvider(searchQuery)),
                  ),
                ] else ...[
                  LibrarySectionHeading(title: _copy.libraryPlaylists),
                  featured.when(
                    data: (data) => _FeaturedPlaylistsSection(
                      playlists: data.items,
                      emptyLabel: _copy.libraryPlaylistsEmpty,
                      thumbnailFor: _playlistThumbnail,
                    ),
                    loading: () => _LoadingBlock(loadingLabel: _copy.libraryLoading),
                    error: (error, _) => _ErrorBlock(
                      message: parseApiError(error).message,
                      retryLabel: _copy.retry,
                      onRetry: () =>
                          ref.invalidate(featuredYoutubePlaylistsProvider),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      BrandTokens.screenPadding,
                      0,
                      BrandTokens.screenPadding,
                      8,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Semantics(
                        button: true,
                        label: _copy.libraryViewAllPlaylists,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const LibraryPlaylistsScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            minimumSize: const Size(
                              _libraryMinTapTarget,
                              _libraryMinTapTarget,
                            ),
                            foregroundColor: UdaanColors.primary,
                          ),
                          child: Text(
                            _copy.libraryViewAllPlaylists,
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  LibrarySectionHeading(
                    title: _copy.libraryRecentUploads,
                  ),
                  recent.when(
                    data: (data) => _VideoListSection(
                      videos: data.items,
                      emptyLabel: _copy.libraryRecentUploadsEmpty,
                    ),
                    loading: () => _LoadingBlock(loadingLabel: _copy.libraryLoading),
                    error: (error, _) => _ErrorBlock(
                      message: parseApiError(error).message,
                      retryLabel: _copy.retry,
                      onRetry: () =>
                          ref.invalidate(libraryRecentUploadsProvider),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _compactPlaylistIcon(int index) {
  const icons = [
    Icons.mic_none_outlined,
    Icons.school_outlined,
    Icons.podcasts_outlined,
    Icons.library_music_outlined,
  ];
  return icons[index % icons.length];
}

class _FeaturedPlaylistsSection extends StatelessWidget {
  const _FeaturedPlaylistsSection({
    required this.playlists,
    required this.emptyLabel,
    required this.thumbnailFor,
  });

  final List<YoutubePlaylist> playlists;
  final String emptyLabel;
  final String Function(YoutubePlaylist playlist) thumbnailFor;

  @override
  Widget build(BuildContext context) {
    if (playlists.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: BrandTokens.screenPadding),
        child: Semantics(
          label: emptyLabel,
          liveRegion: true,
          child: Text(
            emptyLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: UdaanColors.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    void openPlaylist(YoutubePlaylist playlist) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LibraryPlaylistVideosScreen(playlist: playlist),
        ),
      );
    }

    final featured = playlists.first;
    final rest = playlists.length > 1 ? playlists.sublist(1) : <YoutubePlaylist>[];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BrandTokens.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LibraryPlaylistFeaturedTile(
            playlist: featured,
            thumbnailUrl: thumbnailFor(featured),
            onTap: () => openPlaylist(featured),
          ),
          if (rest.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (var i = 0; i < rest.length; i += 2) ...[
              if (i > 0) const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: LibraryPlaylistCompactTile(
                      playlist: rest[i],
                      thumbnailUrl: thumbnailFor(rest[i]),
                      icon: _compactPlaylistIcon(i),
                      onTap: () => openPlaylist(rest[i]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (i + 1 < rest.length)
                    Expanded(
                      child: LibraryPlaylistCompactTile(
                        playlist: rest[i + 1],
                        thumbnailUrl: thumbnailFor(rest[i + 1]),
                        icon: _compactPlaylistIcon(i + 1),
                        onTap: () => openPlaylist(rest[i + 1]),
                      ),
                    )
                  else
                    const Expanded(child: SizedBox()),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _VideoListSection extends ConsumerWidget {
  const _VideoListSection({
    required this.videos,
    required this.emptyLabel,
  });

  final List<YoutubeVideo> videos;
  final String emptyLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (videos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: BrandTokens.screenPadding),
        child: Semantics(
          label: emptyLabel,
          liveRegion: true,
          child: Text(
            emptyLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: UdaanColors.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BrandTokens.screenPadding),
      child: Column(
        children: [
          for (final video in videos) ...[
            LibraryVideoCard(
              video: video,
              thumbnailUrl: libraryThumbnailFor(ref, video),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _SearchResultsSection extends ConsumerWidget {
  const _SearchResultsSection({
    required this.results,
    required this.searchEmptyLabel,
    required this.onRetry,
  });

  final AsyncValue<YoutubeVideoListResponse>? results;
  final String searchEmptyLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = results;
    if (async == null) return const SizedBox.shrink();
    final copy = ref.watch(appCopyProvider);

    return async.when(
      data: (data) => _VideoListSection(
        videos: data.items,
        emptyLabel: searchEmptyLabel,
      ),
      loading: () => _LoadingBlock(loadingLabel: copy.libraryLoading),
      error: (error, _) => _ErrorBlock(
        message: parseApiError(error).message,
        retryLabel: copy.retry,
        onRetry: onRetry,
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({required this.loadingLabel});

  final String loadingLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Semantics(
          label: loadingLabel,
          liveRegion: true,
          child: const CircularProgressIndicator(color: UdaanColors.primary),
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(BrandTokens.screenPadding),
      child: EmptyState(
        message: message,
        icon: Icons.error_outline,
        actionLabel: retryLabel,
        onAction: onRetry,
      ),
    );
  }
}

class _SavedEntryTile extends ConsumerWidget {
  const _SavedEntryTile({required this.copy});

  final AppCopy copy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(appFavoritesProvider).length;
    final countLabel = count > 0 ? ' ($count)' : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BrandTokens.screenPadding,
        8,
        BrandTokens.screenPadding,
        0,
      ),
      child: Semantics(
        button: true,
        label:
            '${copy.librarySavedScreenTitle}$countLabel. ${copy.librarySavedEntrySubtitle}',
        child: Material(
          color: UdaanColors.surfaceContainer,
          borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const LibrarySavedScreen(),
              ),
            ),
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
                border: Border.all(color: UdaanColors.outlineVariant),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.bookmark,
                    color: UdaanColors.primaryGlow,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          copy.librarySavedScreenTitle,
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: UdaanColors.onBackground,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          copy.librarySavedEntrySubtitle,
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: UdaanColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (count > 0)
                    ExcludeSemantics(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: UdaanColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$count',
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontWeight: FontWeight.w800,
                            color: UdaanColors.primaryGlow,
                          ),
                        ),
                      ),
                    ),
                  const Icon(
                    Icons.chevron_right,
                    color: UdaanColors.onSurfaceVariant,
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
