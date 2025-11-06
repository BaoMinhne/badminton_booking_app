import 'package:flutter/foundation.dart';

import '../../models/community_post.dart';
import '../../models/recruitment_post.dart';
import '../../services/post_service.dart';
import '../../services/recruitment_service.dart';

class SocialManager with ChangeNotifier {
  SocialManager({
    PostService? postService,
    RecruitmentService? recruitmentService,
  })  : _postService = postService ?? PostService(),
        _recruitmentService = recruitmentService ?? RecruitmentService();

  final PostService _postService;
  final RecruitmentService _recruitmentService;

  bool _isLoadingPosts = false;
  bool _isLoadingRecruitments = false;
  bool _isCreatingPost = false;
  bool _isCreatingRecruitment = false;
  final Set<String> _joiningRecruitmentIds = {};

  List<CommunityPost> _posts = const [];
  List<RecruitmentPost> _recruitmentPosts = const [];
  String? _postErrorMessage;
  String? _recruitmentErrorMessage;

  bool get isLoadingPosts => _isLoadingPosts;
  bool get isLoadingRecruitments => _isLoadingRecruitments;
  bool get isCreatingPost => _isCreatingPost;
  bool get isCreatingRecruitment => _isCreatingRecruitment;
  List<CommunityPost> get posts => _posts;
  List<RecruitmentPost> get recruitmentPosts => _recruitmentPosts;
  String? get postErrorMessage => _postErrorMessage;
  String? get recruitmentErrorMessage => _recruitmentErrorMessage;

  bool isJoiningRecruitment(String recruitmentId) =>
      _joiningRecruitmentIds.contains(recruitmentId);

  Future<void> loadInitialData(String? currentUserId) async {
    await Future.wait([
      refreshPosts(),
      refreshRecruitmentPosts(currentUserId: currentUserId),
    ]);
  }

  Future<void> refreshPosts() async {
    _isLoadingPosts = true;
    _postErrorMessage = null;
    notifyListeners();

    try {
      _posts = await _postService.fetchPosts();
    } on PostServiceException catch (error) {
      _postErrorMessage = error.message;
    } finally {
      _isLoadingPosts = false;
      notifyListeners();
    }
  }

  Future<void> refreshRecruitmentPosts({String? currentUserId}) async {
    _isLoadingRecruitments = true;
    _recruitmentErrorMessage = null;
    notifyListeners();

    try {
      _recruitmentPosts =
          await _recruitmentService.fetchRecruitmentPosts(
        currentUserId: currentUserId,
      );
    } on RecruitmentServiceException catch (error) {
      _recruitmentErrorMessage = error.message;
    } finally {
      _isLoadingRecruitments = false;
      notifyListeners();
    }
  }

  Future<CommunityPost?> createPost({
    required String authorId,
    required String content,
  }) async {
    if (_isCreatingPost) return null;

    _isCreatingPost = true;
    notifyListeners();

    try {
      final newPost = await _postService.createPost(
        authorId: authorId,
        content: content,
      );
      _posts = [newPost, ..._posts];
      return newPost;
    } on PostServiceException catch (error) {
      _postErrorMessage = error.message;
      rethrow;
    } finally {
      _isCreatingPost = false;
      notifyListeners();
    }
  }

  Future<RecruitmentPost?> createRecruitmentPost({
    required String authorId,
    required String content,
    required DateTime eventTime,
    required int targetMemberCount,
    String? courtId,
    String? skillLevel,
    String? playStyle,
    String? locationNote,
    DateTime? expiresAt,
  }) async {
    if (_isCreatingRecruitment) return null;

    _isCreatingRecruitment = true;
    notifyListeners();

    try {
      final post = await _recruitmentService.createRecruitmentPost(
        authorId: authorId,
        content: content,
        eventTime: eventTime,
        targetMemberCount: targetMemberCount,
        courtId: courtId,
        skillLevel: skillLevel,
        playStyle: playStyle,
        locationNote: locationNote,
        expiresAt: expiresAt,
      );
      _recruitmentPosts = [post, ..._recruitmentPosts];
      return post;
    } on RecruitmentServiceException catch (error) {
      _recruitmentErrorMessage = error.message;
      rethrow;
    } finally {
      _isCreatingRecruitment = false;
      notifyListeners();
    }
  }

  void addRecruitmentPost(RecruitmentPost post) {
    _recruitmentPosts = [post, ..._recruitmentPosts];
    notifyListeners();
  }

  Future<void> joinRecruitment({
    required String recruitmentId,
    required String userId,
  }) async {
    if (_joiningRecruitmentIds.contains(recruitmentId)) {
      return;
    }
    _joiningRecruitmentIds.add(recruitmentId);
    notifyListeners();

    try {
      await _recruitmentService.joinRecruitment(
        recruitmentId: recruitmentId,
        userId: userId,
      );

      final index =
          _recruitmentPosts.indexWhere((post) => post.id == recruitmentId);
      if (index != -1) {
        final post = _recruitmentPosts[index];
        final updatedApplicants = [
          ...post.applicants,
          RecruitmentApplicant(
            id: 'local-$userId',
            recruitmentId: recruitmentId,
            userId: userId,
            createdAt: DateTime.now(),
          ),
        ];
        _recruitmentPosts = [
          ..._recruitmentPosts.sublist(0, index),
          post.copyWith(
            applicants: updatedApplicants,
            hasCurrentUserJoined: true,
          ),
          ..._recruitmentPosts.sublist(index + 1),
        ];
      }
    } on RecruitmentServiceException catch (error) {
      _recruitmentErrorMessage = error.message;
      rethrow;
    } finally {
      _joiningRecruitmentIds.remove(recruitmentId);
      notifyListeners();
    }
  }
}
