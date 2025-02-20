import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _favoritesKey = 'favorite_sounds';
  static final StorageService _instance = StorageService._internal();

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  Future<List<String>> getFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList(_favoritesKey) ?? [];
      return favorites;
    } catch (e) {
      return [];
    }
  }

  Future<void> addToFavorites(String soundId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = await getFavorites();

      if (!favorites.contains(soundId)) {
        favorites.add(soundId);
        await prefs.setStringList(_favoritesKey, favorites);
      }
    } catch (e) {
      print('Error adding to favorites: $e');
    }
  }

  Future<void> removeFromFavorites(String soundId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    favorites.remove(soundId);
    await prefs.setStringList(_favoritesKey, favorites);
  }

  Future<bool> isFavorite(String soundId) async {
    final favorites = await getFavorites();
    return favorites.contains(soundId);
  }
}
