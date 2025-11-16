import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../models/recruitment_post.dart';
import '../../services/pocketbase_client.dart';
import '../../services/recruitment_service.dart';

class RecruitmentManager extends ChangeNotifier {
  RecruitmentManager() : _service = RecruitmentService() {
    _initializeRealtime();
  }

  final RecruitmentService _service;

  bool _isDisposed = false;
  bool _isLoadingRecruitments = false;

  List<RecruitmentPost> _recruitmentPosts = const [];
  String? _recruitmentError;

  final Set<String> _joiningRecruitments = <String>{};

  UnsubscribeFunc? _postsUnsubscribe;
  UnsubscribeFunc? _applicantsUnsubscribe;

  bool get isLoadingRecruitments => _isLoadingRecruitments;
  List<RecruitmentPost> get recruitmentPosts => _recruitmentPosts;
  String? get recruitmentError => _recruitmentError;

  bool isJoining(String recruitmentId) =>
      _joiningRecruitments.contains(recruitmentId);

  Future<void> refreshRecruitments() async {
    _isLoadingRecruitments = true;
    _recruitmentError = null;
    notifyListeners();

    try {
      final results = await _service.fetchActivePosts();
      _recruitmentPosts = results;
    } on RecruitmentServiceException catch (error) {
      _recruitmentError = error.message;
    } finally {
      _isLoadingRecruitments = false;
      notifyListeners();
    }
  }

  Future<void> joinRecruitment(String recruitmentId) async {
    if (_joiningRecruitments.contains(recruitmentId)) {
      return;
    }

    _joiningRecruitments.add(recruitmentId);
    notifyListeners();

    try {
      final updated = await _service.joinRecruitment(recruitmentId);
      _recruitmentPosts = _recruitmentPosts
          .map((post) => post.id == recruitmentId ? updated : post)
          .toList(growable: false);
    } finally {
      _joiningRecruitments.remove(recruitmentId);
      notifyListeners();
    }
  }

  void _initializeRealtime() {
    unawaited(_setupRecruitmentPostsRealtime());
    unawaited(_setupRecruitmentApplicantsRealtime());
  }

  Future<void> _setupRecruitmentPostsRealtime() async {
    try {
      final pocketBase = await getPocketbaseInstance();

      final oldUnsub = _postsUnsubscribe;
      _postsUnsubscribe = null;
      if (oldUnsub != null) {
        await oldUnsub();
      }

      _postsUnsubscribe = await pocketBase
          .collection(RecruitmentService.recruitmentPostsCollection)
          .subscribe(
            '*',
            _handleRecruitmentPostEvent,
            expand: 'author,court',
          );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to initialize recruitment posts realtime: $error');
        debugPrint(stackTrace.toString());
      }
    }
  }

  Future<void> _setupRecruitmentApplicantsRealtime() async {
    try {
      final pocketBase = await getPocketbaseInstance();

      final oldUnsub = _applicantsUnsubscribe;
      _applicantsUnsubscribe = null;
      if (oldUnsub != null) {
        await oldUnsub();
      }

      _applicantsUnsubscribe = await pocketBase
          .collection(RecruitmentService.recruitmentApplicantsCollection)
          .subscribe(
            '*',
            _handleRecruitmentApplicantEvent,
            expand: 'user,recruitment',
          );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
            'Failed to initialize recruitment applicants realtime: $error');
        debugPrint(stackTrace.toString());
      }
    }
  }

  Future<void> _handleRecruitmentPostEvent(
    RecordSubscriptionEvent event,
  ) async {
    if (_isDisposed) {
      return;
    }

    final record = event.record;
    if (record == null) {
      return;
    }

    try {
      switch (event.action) {
        case 'delete':
          _removeRecruitment(record.id);
          break;
        case 'create':
        case 'update':
          final isActive = record.data['is_active'] != false;
          if (!isActive) {
            _removeRecruitment(record.id);
            break;
          }
          final updated = await _service.getRecruitmentById(record.id);
          final index =
              _recruitmentPosts.indexWhere((item) => item.id == updated.id);
          if (index == -1) {
            _recruitmentPosts = [updated, ..._recruitmentPosts];
          } else {
            final posts = List<RecruitmentPost>.from(_recruitmentPosts);
            posts[index] = updated;
            _recruitmentPosts = posts;
          }
          break;
        default:
          break;
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to process recruitment realtime event: $error');
        debugPrint(stackTrace.toString());
      }
    } finally {
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  Future<void> _handleRecruitmentApplicantEvent(
    RecordSubscriptionEvent event,
  ) async {
    if (_isDisposed) {
      return;
    }

    final record = event.record;
    if (record == null) {
      return;
    }

    final recruitmentId = _extractRelationId(record, 'recruitment');
    if (recruitmentId == null) {
      return;
    }

    final index =
        _recruitmentPosts.indexWhere((post) => post.id == recruitmentId);
    if (index == -1) {
      return;
    }

    final recruitment = _recruitmentPosts[index];

    try {
      final pocketBase = await getPocketbaseInstance();
      final currentUserId = pocketBase.authStore.record?.id;
      final applicantUserId = _extractRelationId(record, 'user');

      switch (event.action) {
        case 'create':
          final updated = recruitment.copyWith(
            joinedPlayers: recruitment.joinedPlayers + 1,
            isJoined: recruitment.isJoined ||
                (currentUserId != null && currentUserId == applicantUserId),
          );
          _replaceRecruitmentAt(index, updated);
          break;
        case 'delete':
          final newCount = recruitment.joinedPlayers > 1
              ? recruitment.joinedPlayers - 1
              : recruitment.joinedPlayers;
          final updated = recruitment.copyWith(
            joinedPlayers: newCount,
            isJoined: currentUserId != null && currentUserId == applicantUserId
                ? recruitment.isOwner
                : recruitment.isJoined,
          );
          _replaceRecruitmentAt(index, updated);
          break;
        default:
          break;
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to process applicant realtime event: $error');
        debugPrint(stackTrace.toString());
      }
    } finally {
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  void _replaceRecruitmentAt(int index, RecruitmentPost updated) {
    final posts = List<RecruitmentPost>.from(_recruitmentPosts);
    posts[index] = updated;
    _recruitmentPosts = posts;
  }

  void _removeRecruitment(String recruitmentId) {
    _recruitmentPosts = _recruitmentPosts
        .where((post) => post.id != recruitmentId)
        .toList(growable: false);
  }

  String? _extractRelationId(RecordModel record, String field) {
    // 1. Lấy thẳng id từ data nếu có
    final Object? dataValue = record.data[field];
    if (dataValue is String && dataValue.isNotEmpty) {
      return dataValue;
    }

    // 2. Lấy từ expand (map có thể null)
    final expandMap = record.expand;
    if (expandMap == null) {
      return null;
    }

    final Object? expanded = expandMap[field];

    // Trường hợp expand là 1 RecordModel
    if (expanded is RecordModel) {
      return expanded.id;
    }

    // Trường hợp expand là list RecordModel
    if (expanded is List) {
      if (expanded.isNotEmpty) {
        final first = expanded.first;
        if (first is RecordModel) {
          return first.id;
        }
      }
    }

    return null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    final unsubList = [
      _postsUnsubscribe,
      _applicantsUnsubscribe,
    ];
    for (final unsub in unsubList) {
      if (unsub != null) {
        unawaited(unsub());
      }
    }
    _postsUnsubscribe = null;
    _applicantsUnsubscribe = null;
    super.dispose();
  }
}
