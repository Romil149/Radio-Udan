import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'radio_favorite_show_ids';

class RadioFavoritesStorage {
  RadioFavoritesStorage(this._prefs);

  final SharedPreferences _prefs;

  static Future<RadioFavoritesStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return RadioFavoritesStorage(prefs);
  }

  Set<String> readFavorites() {
    final raw = _prefs.getStringList(_prefsKey) ?? const <String>[];
    return raw.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
  }

  Future<Set<String>> toggle(String showId) async {
    final id = showId.trim();
    if (id.isEmpty) return readFavorites();

    final current = readFavorites();
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    await _prefs.setStringList(_prefsKey, current.toList()..sort());
    return current;
  }
}

final radioFavoritesStorageProvider =
    FutureProvider<RadioFavoritesStorage>((ref) async {
  return RadioFavoritesStorage.create();
});

final radioFavoritesProvider =
    StateNotifierProvider<RadioFavoritesNotifier, Set<String>>((ref) {
  return RadioFavoritesNotifier(ref);
});

class RadioFavoritesNotifier extends StateNotifier<Set<String>> {
  RadioFavoritesNotifier(this._ref) : super(const <String>{}) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final storage = await _ref.read(radioFavoritesStorageProvider.future);
    state = storage.readFavorites();
  }

  bool isFavorite(String showId) {
    final id = showId.trim();
    if (id.isEmpty) return false;
    return state.contains(id);
  }

  Future<void> toggle(String showId) async {
    final storage = await _ref.read(radioFavoritesStorageProvider.future);
    state = await storage.toggle(showId);
  }
}

