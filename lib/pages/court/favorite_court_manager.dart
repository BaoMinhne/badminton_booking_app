import 'package:flutter/foundation.dart';

import '../../models/court.dart';
import '../../services/favorite_court_service.dart';
import '../../services/user_service.dart';

class FavoriteCourtManager with ChangeNotifier {
  FavoriteCourtManager({
    FavoriteCourtService? favoriteCourtService,
    UserDetailsService? userDetailsService,
  })  : _favoriteService = favoriteCourtService ?? FavoriteCourtService(),
        _userDetailsService = userDetailsService ?? UserDetailsService();

  final FavoriteCourtService _favoriteService;
  final UserDetailsService _userDetailsService;

  bool _isLoading = false;
  Set<String> _favoriteCourtIds = <String>{};
  String? _userId;

  bool get isLoading => _isLoading;
  Set<String> get favoriteCourtIds => Set.unmodifiable(_favoriteCourtIds);

  bool isFavorite(String courtId) => _favoriteCourtIds.contains(courtId);

  Future<void> initialize() async {
    if (_userId != null || _isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      _userId = await _userDetailsService.getCurrentUserId();
      if (_userId == null) {
        _favoriteCourtIds = <String>{};
        return;
      }

      _favoriteCourtIds = await _favoriteService.getFavoriteCourtIds(_userId!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _userId = await _userDetailsService.getCurrentUserId();
    if (_userId == null) {
      _favoriteCourtIds = <String>{};
      notifyListeners();
      return;
    }

    _favoriteCourtIds = await _favoriteService.getFavoriteCourtIds(_userId!);
    notifyListeners();
  }

  Future<void> toggleFavorite(Court court) async {
    final userId = _userId ?? await _userDetailsService.getCurrentUserId();
    if (userId == null) return;

    final isCurrentlyFavorite = _favoriteCourtIds.contains(court.id);
    _favoriteCourtIds = Set<String>.from(_favoriteCourtIds)
      ..toggle(court.id, isCurrentlyFavorite);
    notifyListeners();

    try {
      if (isCurrentlyFavorite) {
        await _favoriteService.removeFavorite(userId, court.id);
      } else {
        await _favoriteService.addFavorite(userId, court);
      }
    } catch (_) {
      // revert on failure
      _favoriteCourtIds = Set<String>.from(_favoriteCourtIds)
        ..toggle(court.id, !isCurrentlyFavorite);
      notifyListeners();
      rethrow;
    }
  }
}

extension on Set<String> {
  void toggle(String courtId, bool isFavorite) {
    if (isFavorite) {
      remove(courtId);
    } else {
      add(courtId);
    }
  }
}
