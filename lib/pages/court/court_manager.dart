import 'package:flutter/foundation.dart';

import '../../models/court.dart';
import '../../services/court_service.dart';

class CourtManager with ChangeNotifier {
  CourtManager({CourtService? courtService})
      : _courtService = courtService ?? CourtService() {
    loadCourts();
  }

  final CourtService _courtService;

  bool _isLoading = false;
  String? _errorMessage;
  List<Court> _courts = const [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Court> get courts => List.unmodifiable(_courts);
  CourtService get courtService => _courtService;

  Future<void> loadCourts({bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (_courts.isNotEmpty && !forceRefresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _courtService.listCourts();
      _courts = result;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print('Failed to load courts: $error');
        print(stackTrace);
      }
      _errorMessage = _resolveErrorMessage(
        error,
        'Không thể tải danh sách sân. Vui lòng thử lại.',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() {
    return loadCourts(forceRefresh: true);
  }

  String _resolveErrorMessage(Object error, String fallback) {
    if (error is CourtServiceException) {
      return error.message;
    }

    final message = error.toString();
    if (message.startsWith('Exception:')) {
      final trimmed = message.substring('Exception:'.length).trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }

    if (message.isNotEmpty) {
      return message;
    }

    return fallback;
  }
}
