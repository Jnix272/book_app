import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/models.dart';

class FavoritesService extends ChangeNotifier {
  static final FavoritesService instance = FavoritesService._internal();
  FavoritesService._internal();

  static const String _favoritesKey = 'user_favorites';
  SharedPreferences? _prefs;
  Set<String> _favoriteIds = {};

  Set<String> get favoriteIds => _favoriteIds;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final List<String> storedFavorites =
        _prefs?.getStringList(_favoritesKey) ?? [];
    _favoriteIds = storedFavorites.toSet();
    notifyListeners();
  }

  bool isFavorite(String providerId) {
    return _favoriteIds.contains(providerId);
  }

  Future<void> toggleFavorite(String providerId) async {
    if (_favoriteIds.contains(providerId)) {
      _favoriteIds.remove(providerId);
    } else {
      _favoriteIds.add(providerId);
    }
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> _saveFavorites() async {
    if (_prefs != null) {
      await _prefs!.setStringList(_favoritesKey, _favoriteIds.toList());
    }
  }

  // Optional: Cache fetched providers to avoid redundant network calls
  final Map<String, ServiceProvider> _cachedProviders = {};

  void cacheProviders(List<ServiceProvider> providers) {
    for (final p in providers) {
      _cachedProviders[p.id] = p;
    }
  }

  ServiceProvider? getCachedProvider(String id) => _cachedProviders[id];
}
