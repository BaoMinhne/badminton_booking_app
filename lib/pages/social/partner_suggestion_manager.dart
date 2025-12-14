import 'dart:async';

import 'package:badminton_booking_app/models/partner_recommendation.dart';
import 'package:badminton_booking_app/models/friend_relation.dart';
import 'package:badminton_booking_app/services/recommender_service.dart';
import 'package:badminton_booking_app/services/friend_request_service.dart';
import 'package:flutter/foundation.dart';

class PartnerSuggestionManager extends ChangeNotifier {
  PartnerSuggestionManager({
    RecommenderService? service,
    FriendRequestService? friendRequestService,
  })  : _service = service ?? RecommenderService(),
        _friendRequestService = friendRequestService ?? FriendRequestService();

  final RecommenderService _service;
  final FriendRequestService _friendRequestService;
  bool _isDisposed = false;

  List<PartnerRecommendation> _suggestions = const <PartnerRecommendation>[];
  List<PartnerRecommendation> _filteredSuggestions =
      const <PartnerRecommendation>[];
  bool _isLoading = false;
  String? _error;

  String? _selectedMatchType;
  String? _selectedIntensity;
  bool _onlyHomeCourt = false;
  double _minMatchScore = 0;
  bool _hideExistingRelations = false;
  String? _homeCourtId;
  bool _hasLoggedShown = false;
  final Set<String> _dismissedUserIds = <String>{};
  final Map<String, FriendRelationStatus> _relations =
      <String, FriendRelationStatus>{};

  List<PartnerRecommendation> get suggestions => _filteredSuggestions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get minMatchScore => _minMatchScore;
  String? get selectedMatchType => _selectedMatchType;
  String? get selectedIntensity => _selectedIntensity;
  bool get onlyHomeCourt => _onlyHomeCourt;
  bool get hideExistingRelations => _hideExistingRelations;
  String? get homeCourtId => _homeCourtId;

  Future<void> loadSuggestions({bool force = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    _hasLoggedShown = false;
    if (force) {
      _suggestions = const <PartnerRecommendation>[];
      _filteredSuggestions = const <PartnerRecommendation>[];
    }
    _notifyListeners();

    try {
      final results = await _service.fetchRecommendations();
      _suggestions = results
          .where((rec) => !_dismissedUserIds.contains(rec.friend.user.id))
          .toList(growable: false);
      await _maybeLoadRelations();
      _applyFilters();
    } catch (err) {
      _error = err.toString();
      _filteredSuggestions = const <PartnerRecommendation>[];
    } finally {
      _isLoading = false;
      _notifyListeners();
    }
  }

  void setMatchType(String? matchType) {
    if (_selectedMatchType == matchType) return;
    _selectedMatchType = matchType;
    _applyFilters();
  }

  void setIntensity(String? intensity) {
    if (_selectedIntensity == intensity) return;
    _selectedIntensity = intensity;
    _applyFilters();
  }

  void setHomeCourtOnly(bool value) {
    if (_onlyHomeCourt == value) return;
    _onlyHomeCourt = value;
    _applyFilters();
  }

  void setMinMatchScore(double value) {
    if (_minMatchScore == value) return;
    _minMatchScore = value;
    _applyFilters();
  }

  Future<void> setHideExistingRelations(bool value) async {
    if (_hideExistingRelations == value) return;
    _hideExistingRelations = value;
    if (value) {
      await _maybeLoadRelations();
    }
    _applyFilters();
  }

  void setHomeCourtId(String? id) {
    if (_homeCourtId == id) return;
    _homeCourtId = id;
    if (_onlyHomeCourt) {
      _applyFilters();
    }
  }

  Future<void> _maybeLoadRelations() async {
    if (!_hideExistingRelations || _suggestions.isEmpty) return;

    final idsToFetch = _suggestions
        .map((rec) => rec.friend.user.id)
        .where((id) => !_relations.containsKey(id))
        .toList(growable: false);

    if (idsToFetch.isEmpty) return;

    try {
      final results = await Future.wait(
        idsToFetch.map(_friendRequestService.getRelationStatus),
      );

      for (int i = 0; i < idsToFetch.length; i++) {
        _relations[idsToFetch[i]] = results[i];
      }
    } catch (_) {
      // Nếu không lấy được trạng thái quan hệ, bỏ qua để tránh chặn UI
    }
  }

  void _applyFilters() {
    _filteredSuggestions = _suggestions.where((suggestion) {
      final details = suggestion.friend.details;

      if (_dismissedUserIds.contains(suggestion.friend.user.id)) {
        return false;
      }

      if (_selectedMatchType != null &&
          !(details?.matchTypes.contains(_selectedMatchType) ?? false)) {
        return false;
      }

      if (_selectedIntensity != null &&
          details?.intensity != _selectedIntensity) {
        return false;
      }

      if (_onlyHomeCourt && _homeCourtId != null) {
        if (details?.homeCourtId != _homeCourtId) return false;
      }

      if (suggestion.matchScore < _minMatchScore) {
        return false;
      }

      if (_hideExistingRelations) {
        final relation =
            _relations[suggestion.friend.user.id] ?? const FriendRelationStatus.none();
        if (relation.type != FriendRelationType.none) {
          return false;
        }
      }

      return true;
    }).toList(growable: false);

    _notifyListeners();
    _logShownIfNeeded();
  }

  void dismissSuggestion(String userId) {
    _dismissedUserIds.add(userId);
    _suggestions = _suggestions
        .where((suggestion) => suggestion.friend.user.id != userId)
        .toList(growable: false);
    _applyFilters();
  }

  Future<void> logProfileClicked(String userId) async {
    await _safeLog(() => _service.logProfileClicked(userId));
  }

  Future<void> logInviteAction(String userId) async {
    await _safeLog(
      () => _service.logRecommendationAction(action: 'invited', targetUserId: userId),
    );
  }

  Future<void> logActionOutcome(String userId, String outcome) async {
    await _safeLog(
      () => _service.logRecommendationOutcome(outcome: outcome, targetUserId: userId),
    );
  }

  void _logShownIfNeeded() {
    if (_hasLoggedShown || _filteredSuggestions.isEmpty) return;
    _hasLoggedShown = true;

    final ids = _filteredSuggestions
        .map((suggestion) => suggestion.friend.user.id)
        .toList(growable: false);

    unawaited(_safeLog(() => _service.logRecommendationsShown(ids)));
  }

  Future<void> _safeLog(Future<void> Function() runner) async {
    try {
      await runner();
    } catch (_) {
      // Bỏ qua lỗi log để không ảnh hưởng trải nghiệm người dùng
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _notifyListeners() {
    if (_isDisposed) return;
    notifyListeners();
  }
}
