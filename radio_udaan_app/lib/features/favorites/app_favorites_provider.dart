import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/saved_favorite.dart';
import '../../core/models/youtube_video.dart';
import '../../core/network/dio_exception_mapper.dart';
import '../../core/providers/app_providers.dart';

const _prefsKey = 'app_saved_favorites_v1';
const _legacyRadioKey = 'radio_favorite_show_ids';
const _legacyLibraryKey = 'library_saved_video_ids';

class AppFavoritesStorage {
  AppFavoritesStorage(this._prefs);

  final SharedPreferences _prefs;

  static Future<AppFavoritesStorage> create() async {
    return AppFavoritesStorage(await SharedPreferences.getInstance());
  }

  List<SavedFavorite> readAll() {
    final raw = _prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return SavedFavorite.listFromJson(decoded);
        }
      } catch (_) {}
    }
    return _migrateLegacy();
  }

  List<SavedFavorite> _migrateLegacy() {
    final items = <SavedFavorite>[];
    final radio = _prefs.getStringList(_legacyRadioKey) ?? const <String>[];
    for (final id in radio) {
      final trimmed = id.trim();
      if (trimmed.isEmpty) continue;
      items.add(
        SavedFavorite(
          type: SavedFavoriteType.radioShow,
          itemId: trimmed,
          title: '',
        ),
      );
    }
    final videos = _prefs.getStringList(_legacyLibraryKey) ?? const <String>[];
    for (final id in videos) {
      final trimmed = id.trim();
      if (trimmed.isEmpty) continue;
      items.add(
        SavedFavorite(
          type: SavedFavoriteType.libraryVideo,
          itemId: trimmed,
          title: '',
        ),
      );
    }
    if (items.isNotEmpty) {
      _write(items);
      _prefs.remove(_legacyRadioKey);
      _prefs.remove(_legacyLibraryKey);
    }
    return items;
  }

  Future<void> writeAll(List<SavedFavorite> items) async {
    await _write(items);
  }

  Future<void> _write(List<SavedFavorite> items) async {
    final encoded = jsonEncode(items.map((e) => e.toLocalJson()).toList());
    await _prefs.setString(_prefsKey, encoded);
  }
}

final appFavoritesStorageProvider =
    FutureProvider<AppFavoritesStorage>((ref) async {
  return AppFavoritesStorage.create();
});

final appFavoritesProvider =
    StateNotifierProvider<AppFavoritesNotifier, List<SavedFavorite>>((ref) {
  return AppFavoritesNotifier(ref);
});

/// Radio show ids only — compatibility for existing widgets.
final radioFavoritesProvider = Provider<Set<String>>((ref) {
  return ref
      .watch(appFavoritesProvider)
      .where((item) => item.type == SavedFavoriteType.radioShow)
      .map((item) => item.itemId)
      .toSet();
});

/// Library video ids only — compatibility for existing widgets.
final librarySavedVideoIdsProvider = Provider<Set<String>>((ref) {
  return ref
      .watch(appFavoritesProvider)
      .where((item) => item.type == SavedFavoriteType.libraryVideo)
      .map((item) => item.itemId)
      .toSet();
});

class AppFavoritesNotifier extends StateNotifier<List<SavedFavorite>> {
  AppFavoritesNotifier(this._ref) : super(const []) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final storage = await _ref.read(appFavoritesStorageProvider.future);
    state = storage.readAll();
  }

  Future<void> _persistLocal() async {
    final storage = await _ref.read(appFavoritesStorageProvider.future);
    await storage.writeAll(state);
  }

  bool isRadioFavorite(String showId) {
    final id = showId.trim();
    if (id.isEmpty) return false;
    return state.any(
      (item) =>
          item.type == SavedFavoriteType.radioShow && item.itemId == id,
    );
  }

  bool isVideoSaved(String videoId) {
    final id = videoId.trim();
    if (id.isEmpty) return false;
    return state.any(
      (item) =>
          item.type == SavedFavoriteType.libraryVideo && item.itemId == id,
    );
  }

  List<SavedFavorite> get radioShows => state
      .where((item) => item.type == SavedFavoriteType.radioShow)
      .toList();

  List<SavedFavorite> get libraryVideos => state
      .where((item) => item.type == SavedFavoriteType.libraryVideo)
      .toList();

  Future<void> toggleRadioShow({
    required String showId,
    required String title,
    Map<String, String> meta = const {},
  }) async {
    final id = showId.trim();
    if (id.isEmpty) return;

    final existingIndex = state.indexWhere(
      (item) => item.type == SavedFavoriteType.radioShow && item.itemId == id,
    );
    final removing = existingIndex >= 0;
    final next = List<SavedFavorite>.from(state);

    if (removing) {
      next.removeAt(existingIndex);
    } else {
      next.insert(
        0,
        SavedFavorite(
          type: SavedFavoriteType.radioShow,
          itemId: id,
          title: title.trim(),
          meta: meta,
        ),
      );
    }

    state = next;
    await _persistLocal();
    await _syncToggleIfSignedIn(
      type: SavedFavoriteType.radioShow,
      itemId: id,
      title: title,
      meta: meta,
      removing: removing,
    );
  }

  Future<void> toggleLibraryVideo({
    required YoutubeVideo video,
    String? thumbnailUrl,
  }) async {
    final id = video.id.trim();
    if (id.isEmpty) return;

    final meta = <String, String>{
      if ((thumbnailUrl ?? video.thumbnailUrl)?.trim().isNotEmpty ?? false)
        'thumbnail_url': (thumbnailUrl ?? video.thumbnailUrl)!.trim(),
      if (video.displayDuration.isNotEmpty) 'duration': video.displayDuration,
      if ((video.description ?? '').trim().isNotEmpty)
        'description': video.description!.trim(),
    };

    final existingIndex = state.indexWhere(
      (item) =>
          item.type == SavedFavoriteType.libraryVideo && item.itemId == id,
    );
    final removing = existingIndex >= 0;
    final next = List<SavedFavorite>.from(state);

    if (removing) {
      next.removeAt(existingIndex);
    } else {
      next.insert(
        0,
        SavedFavorite(
          type: SavedFavoriteType.libraryVideo,
          itemId: id,
          title: video.title.trim(),
          meta: meta,
        ),
      );
    }

    state = next;
    await _persistLocal();
    await _syncToggleIfSignedIn(
      type: SavedFavoriteType.libraryVideo,
      itemId: id,
      title: video.title,
      meta: meta,
      removing: removing,
    );
  }

  Future<void> mergeWithServerAfterLogin() async {
    final token = _ref.read(authTokenProvider);
    if (token == null || token.isEmpty) return;

    try {
      final api = _ref.read(radioudaanApiProvider);
      final merged = await api.syncFavorites(
        localItems: state,
      );
      state = merged;
      await _persistLocal();
    } catch (e) {
      parseApiError(e);
      try {
        final remote = await _ref.read(radioudaanApiProvider).listFavorites();
        state = _unionFavorites(state, remote);
        await _persistLocal();
      } catch (_) {}
    }
  }

  Future<void> _syncToggleIfSignedIn({
    required SavedFavoriteType type,
    required String itemId,
    required String title,
    required Map<String, String> meta,
    required bool removing,
  }) async {
    final token = _ref.read(authTokenProvider);
    if (token == null || token.isEmpty) return;

    try {
      final result = await _ref.read(radioudaanApiProvider).toggleFavorite(
            type: type,
            itemId: itemId,
            title: title,
            meta: meta,
          );
      state = result;
      await _persistLocal();
    } catch (_) {
      if (removing) {
        state = [
          ...state,
          SavedFavorite(
            type: type,
            itemId: itemId,
            title: title,
            meta: meta,
          ),
        ];
      } else {
        state = state
            .where(
              (item) => !(item.type == type && item.itemId == itemId),
            )
            .toList();
      }
      await _persistLocal();
    }
  }

  List<SavedFavorite> _unionFavorites(
    List<SavedFavorite> local,
    List<SavedFavorite> remote,
  ) {
    final byKey = <String, SavedFavorite>{};
    for (final item in remote) {
      byKey['${item.type.apiValue}:${item.itemId}'] = item;
    }
    for (final item in local) {
      final key = '${item.type.apiValue}:${item.itemId}';
      final existing = byKey[key];
      if (existing == null) {
        byKey[key] = item;
        continue;
      }
      if (existing.title.trim().isEmpty && item.title.trim().isNotEmpty) {
        byKey[key] = item.copyWithMeta(existing.meta);
      }
    }
    return byKey.values.toList();
  }
}

extension on SavedFavorite {
  SavedFavorite copyWithMeta(Map<String, String> otherMeta) {
    return SavedFavorite(
      type: type,
      itemId: itemId,
      title: title,
      meta: {...otherMeta, ...meta},
      savedAt: savedAt,
    );
  }
}

/// Legacy notifier alias used by a few widgets.
extension RadioFavoritesNotifierCompat on AppFavoritesNotifier {
  Future<void> toggle(String showId, {String title = '', Map<String, String>? meta}) {
    return toggleRadioShow(
      showId: showId,
      title: title,
      meta: meta ?? const {},
    );
  }
}

extension LibrarySavedNotifierCompat on AppFavoritesNotifier {
  Future<void> toggle(String videoId) {
    return toggleLibraryVideo(
      video: YoutubeVideo(id: videoId, title: ''),
    );
  }
}

final radioFavoritesNotifierProvider = Provider<AppFavoritesNotifier>((ref) {
  return ref.read(appFavoritesProvider.notifier);
});

final librarySavedNotifierProvider = Provider<AppFavoritesNotifier>((ref) {
  return ref.read(appFavoritesProvider.notifier);
});
