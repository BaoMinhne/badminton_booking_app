import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../models/recruitment_post.dart';
import '../../../services/recruitment_service.dart';
import '../../../utils/recruitment_dictionary.dart';

class RecruitmentFormManager with ChangeNotifier {
  RecruitmentFormManager()
      : _service = RecruitmentService(),
        noteController = TextEditingController(),
        memberCountController = TextEditingController(text: '3') {
    _memberCount = 3;
    _selectedPlayStyleLabel = RecruitmentDictionary.playStyleLabels['doubles']!;
    _selectedSkillLevelLabel =
        RecruitmentDictionary.skillLevelLabels['Intermediate']!;
  }

  final RecruitmentService _service;

  final TextEditingController noteController;
  final TextEditingController memberCountController;

  bool _hasBookedCourt = true;
  bool _isLoadingCourts = false;
  bool _isSubmitting = false;
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 2));
  List<BookedCourtOption> _bookedCourts = const [];
  BookedCourtOption? _selectedCourt;
  String? _courtMessage;
  int _memberCount = 3;
  String _selectedPlayStyleLabel = '';
  String _selectedSkillLevelLabel = '';

  bool get hasBookedCourt => _hasBookedCourt;
  bool get isLoadingCourts => _isLoadingCourts;
  bool get isSubmitting => _isSubmitting;
  DateTime get selectedDateTime => _selectedDateTime;
  List<BookedCourtOption> get bookedCourts => _bookedCourts;
  BookedCourtOption? get selectedCourt => _selectedCourt;
  String? get courtMessage => _courtMessage;
  int get memberCount => _memberCount;
  String get selectedPlayStyleLabel => _selectedPlayStyleLabel;
  String get selectedSkillLevelLabel => _selectedSkillLevelLabel;

  List<String> get playStyleOptions =>
      RecruitmentDictionary.playStyleDisplayOptions();
  List<String> get skillLevelOptions =>
      RecruitmentDictionary.skillDisplayOptions();

  Future<void> initialize() async {
    await _loadBookedCourts();
  }

  Future<void> toggleHasBookedCourt(bool value) async {
    _hasBookedCourt = value;
    if (value) {
      await _loadBookedCourts();
    } else {
      _selectedCourt = null;
      _courtMessage = null;
      notifyListeners();
    }
  }

  Future<void> updateSelectedDateTime(DateTime value) async {
    _selectedDateTime = value;
    if (_hasBookedCourt) {
      await _loadBookedCourts();
    } else {
      notifyListeners();
    }
  }

  void updateSelectedCourt(String? bookingId) {
    if (bookingId == null) {
      _selectedCourt = null;
    } else {
      final matched =
          _bookedCourts.where((court) => court.id == bookingId).toList();
      if (matched.isNotEmpty) {
        _selectedCourt = matched.first;
      } else if (_bookedCourts.isNotEmpty) {
        _selectedCourt = _bookedCourts.first;
      } else {
        _selectedCourt = null;
      }
    }
    notifyListeners();
  }

  void updateMemberCount(int value) {
    _memberCount = value < 1 ? 1 : value;
    final normalizedText = _memberCount.toString();
    if (memberCountController.text != normalizedText) {
      memberCountController.text = normalizedText;
      memberCountController.selection = TextSelection.fromPosition(
        TextPosition(offset: normalizedText.length),
      );
    }
    notifyListeners();
  }

  void selectPlayStyle(String label) {
    _selectedPlayStyleLabel = label;
    notifyListeners();
  }

  void selectSkillLevel(String label) {
    _selectedSkillLevelLabel = label;
    notifyListeners();
  }

  Future<RecruitmentPost> submit() async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final result = await _service.createRecruitmentPost(
        hasBookedCourt: _hasBookedCourt,
        playTime: _selectedDateTime,
        needMembers: _memberCount,
        playStyleLabel: _selectedPlayStyleLabel,
        skillLevelLabel: _selectedSkillLevelLabel,
        note: noteController.text,
        courtId: _selectedCourt?.courtId,
        locationNote: _selectedCourt?.bookingView.courtLocation,
      );
      return result;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> _loadBookedCourts() async {
    _isLoadingCourts = true;
    _courtMessage = null;
    notifyListeners();

    try {
      final bookings = await _service.listMyBookingsForDate(_selectedDateTime);
      _bookedCourts = bookings
          .map((view) => BookedCourtOption(bookingView: view))
          .toList(growable: false);

      if (_bookedCourts.isEmpty) {
        _selectedCourt = null;
        _courtMessage =
            'Bạn chưa có sân nào trong ngày ${_formatDate(_selectedDateTime)}';
      } else {
        _selectedCourt ??= _bookedCourts.first;
      }
    } on RecruitmentServiceException catch (error) {
      _bookedCourts = const [];
      _selectedCourt = null;
      _courtMessage = error.message;
    } finally {
      _isLoadingCourts = false;
      notifyListeners();
    }
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  }

  @override
  void dispose() {
    noteController.dispose();
    memberCountController.dispose();
    super.dispose();
  }
}
