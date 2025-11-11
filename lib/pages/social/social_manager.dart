import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../models/community_post.dart';
import '../../models/recruitment_post.dart';
import '../../services/post_service.dart';
import '../../services/recruitment_service.dart';

class SocialManager with ChangeNotifier {
  SocialManager()
      : _postService = PostService(),
        _recruitmentService = RecruitmentService();

  final PostService _postService;
  final RecruitmentService _recruitmentService;

  bool _isLoadingPosts = false;
  bool _isLoadingRecruitments = false;
  bool _isSubmittingPost = false;

  List<CommunityPost> _posts = const [];
  List<RecruitmentPost> _recruitmentPosts = const [];

  String? _postError;
  String? _recruitmentError;

  final Set<String> _joiningRecruitments = <String>{};

  bool get isLoadingPosts => _isLoadingPosts;
  bool get isLoadingRecruitments => _isLoadingRecruitments;
  bool get isSubmittingPost => _isSubmittingPost;

  List<CommunityPost> get posts => _posts;
  List<RecruitmentPost> get recruitmentPosts => _recruitmentPosts;

  String? get postError => _postError;
  String? get recruitmentError => _recruitmentError;

  bool isJoining(String recruitmentId) => _joiningRecruitments.contains(recruitmentId);

  Future<void> loadInitial() async {
    await Future.wait<void>([
      refreshPosts(),
      refreshRecruitments(),
    ]);
  }

  Future<void> refreshPosts() async {
    _isLoadingPosts = true;
    _postError = null;
    notifyListeners();

    try {
      final results = await _postService.fetchPosts();
      _posts = results;
    } on PostServiceException catch (error) {
      _postError = error.message;
    } finally {
      _isLoadingPosts = false;
      notifyListeners();
    }
  }

  Future<void> refreshRecruitments() async {
    _isLoadingRecruitments = true;
    _recruitmentError = null;
    notifyListeners();

    try {
      final results = await _recruitmentService.fetchActivePosts();
      _recruitmentPosts = results;
    } on RecruitmentServiceException catch (error) {
      _recruitmentError = error.message;
    } finally {
      _isLoadingRecruitments = false;
      notifyListeners();
    }
  }

  Future<void> createPost({
    required String content,
    List<File> images = const [],
  }) async {
    _isSubmittingPost = true;
    notifyListeners();

    try {
      final newPost = await _postService.createPost(
        content: content,
        images: images,
      );
      _posts = [newPost, ..._posts];
    } on PostServiceException catch (error) {
      _postError = error.message;
      rethrow;
    } finally {
      _isSubmittingPost = false;
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
      final updated = await _recruitmentService.joinRecruitment(recruitmentId);
      _recruitmentPosts = _recruitmentPosts
          .map((post) => post.id == recruitmentId ? updated : post)
          .toList(growable: false);
    } finally {
      _joiningRecruitments.remove(recruitmentId);
      notifyListeners();
    }
  }
}
