import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_strings.dart';
import '../../core/models/youtube_video.dart';
import '../../core/network/dio_exception_mapper.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/udaan_colors.dart';
import 'library_image_url.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/main_tab_app_bar.dart';
import 'library_playlist_videos_screen.dart';
import 'library_playlists_screen.dart';
import 'library_providers.dart';
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
    final copy = ref.watch(appCopyProvider);
    final searchQuery = ref.watch(librarySearchQueryProvider);
    final isSearching = searchQuery.isNotEmpty;
    final featured = ref.watch(featuredYoutubePlaylistsProvider);
    final recent = ref.watch(libraryRecentUploadsProvider);
    final searchResults = isSearching
        ? ref.watch(libraryYoutubeSearchProvider(searchQuery))
        : null;

    return Scaffold(
      backgroundColor: UdaanColors.background,
      appBar: MainTabAppBar(title: copy.tabLibrary),
      body: SafeArea(
        child: Semantics(
          label: AppStrings.tabLibrary,
          child: RefreshIndicator(
            color: UdaanColors.primary,
            backgroundColor: UdaanColors.surfaceContainer,
            onRefresh: _refreshAll,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                LibrarySearchField(controller: _searchController),
                if (isSearching) ...[
                  _SearchResultsSection(
                    results: searchResults,
                    onRetry: () =>
                        ref.invalidate(libraryYoutubeSearchProvider(searchQuery)),
                  ),
                ] else ...[
                  const LibrarySectionHeading(title: AppStrings.libraryPlaylists),
                  featured.when(
                    data: (data) => _FeaturedPlaylistsSection(
                      playlists: data.items,
                      thumbnailFor: _playlistThumbnail,
                    ),
                    loading: () => const _LoadingBlock(),
                    error: (error, _) => _ErrorBlock(
                      message: parseApiError(error).message,
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
                        label: AppStrings.libraryViewAllPlaylists,
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
                            AppStrings.libraryViewAllPlaylists,
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const LibrarySectionHeading(
                    title: AppStrings.libraryRecentUploads,
                  ),
                  recent.when(
                    data: (data) => _VideoListSection(
                      videos: data.items,
                      emptyLabel: AppStrings.libraryRecentUploadsEmpty,
                    ),
                    loading: () => const _LoadingBlock(),
                    error: (error, _) => _ErrorBlock(
                      message: parseApiError(error).message,
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
    required this.thumbnailFor,
  });

  final List<YoutubePlaylist> playlists;
  final String Function(YoutubePlaylist playlist) thumbnailFor;

  @override
  Widget build(BuildContext context) {
    if (playlists.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: BrandTokens.screenPadding),
        child: Semantics(
          label: AppStrings.libraryPlaylistsEmpty,
          liveRegion: true,
          child: Text(
            AppStrings.libraryPlaylistsEmpty,
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
    required this.onRetry,
  });

  final AsyncValue<YoutubeVideoListResponse>? results;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = results;
    if (async == null) return const SizedBox.shrink();

    return async.when(
      data: (data) => _VideoListSection(
        videos: data.items,
        emptyLabel: AppStrings.librarySearchEmpty,
      ),
      loading: () => const _LoadingBlock(),
      error: (error, _) => _ErrorBlock(
        message: parseApiError(error).message,
        onRetry: onRetry,
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Semantics(
          label: AppStrings.libraryLoading,
          liveRegion: true,
          child: const CircularProgressIndicator(color: UdaanColors.primary),
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(BrandTokens.screenPadding),
      child: EmptyState(
        message: message,
        icon: Icons.error_outline,
        actionLabel: AppStrings.retry,
        onAction: onRetry,
      ),
    );
  }
}
