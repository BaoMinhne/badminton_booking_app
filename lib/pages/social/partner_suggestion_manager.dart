import 'package:badminton_booking_app/models/partner_recommendation.dart';
import 'package:badminton_booking_app/services/recommender_service.dart';
import 'package:flutter/foundation.dart';

class PartnerSuggestionManager extends ChangeNotifier {
  PartnerSuggestionManager({RecommenderService? service})
      : _service = service ?? RecommenderService();

  final RecommenderService _service;

  List<PartnerRecommendation> _suggestions = const <PartnerRecommendation>[];
  bool _isLoading = false;
  String? _error;

  List<PartnerRecommendation> get suggestions => _suggestions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSuggestions({bool force = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    if (force) {
      _suggestions = const <PartnerRecommendation>[];
    }
    notifyListeners();

    try {
      _suggestions = await _service.fetchRecommendations();
    } catch (err) {
      _error = err.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
