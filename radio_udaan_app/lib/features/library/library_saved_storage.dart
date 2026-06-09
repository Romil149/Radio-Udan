import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const librarySavedVideoIdsKey = 'library_saved_video_ids';

class LibrarySavedStorage {
  LibrarySavedStorage(this._prefs);

  final SharedPreferences _prefs;

  static Future<LibrarySavedStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LibrarySavedStorage(prefs);
  }

  Set<String> readSavedIds() {
    final raw = _prefs.getStringList(librarySavedVideoIdsKey) ?? const <String>[];
    return raw.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
  }

  Future<Set<String>> toggle(String videoId) async {
    final id = videoId.trim();
    if (id.isEmpty) return readSavedIds();

    final current = readSavedIds();
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    await _prefs.setStringList(librarySavedVideoIdsKey, current.toList()..sort());
    return current;
  }
}

final librarySavedStorageProvider =
    FutureProvider<LibrarySavedStorage>((ref) async {
  return LibrarySavedStorage.create();
});

final librarySavedVideoIdsProvider =
    StateNotifierProvider<LibrarySavedNotifier, Set<String>>((ref) {
  return LibrarySavedNotifier(ref);
});

class LibrarySavedNotifier extends StateNotifier<Set<String>> {
  LibrarySavedNotifier(this._ref) : super(const <String>{}) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final storage = await _ref.read(librarySavedStorageProvider.future);
    state = storage.readSavedIds();
  }

  bool isSaved(String videoId) {
    final id = videoId.trim();
    if (id.isEmpty) return false;
    return state.contains(id);
  }

  Future<void> toggle(String videoId) async {
    final storage = await _ref.read(librarySavedStorageProvider.future);
    state = await storage.toggle(videoId);
  }
}
