import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../models/community_post.dart';
import '../../models/post_comment.dart';
import '../../models/recruitment_post.dart';
import 'post_manager.dart';
import 'recruitment_manager.dart';

class SocialManager with ChangeNotifier {
  SocialManager()
      : postManager = PostManager(),
        recruitmentManager = RecruitmentManager() {
    _postManagerListener = _propagateChanges;
    _recruitmentManagerListener = _propagateChanges;
    postManager.addListener(_postManagerListener);
    recruitmentManager.addListener(_recruitmentManagerListener);
  }

  final PostManager postManager;
  final RecruitmentManager recruitmentManager;

  late final VoidCallback _postManagerListener;
  late final VoidCallback _recruitmentManagerListener;
  bool _isDisposed = false;

  Future<void> loadInitial() async {
    await Future.wait<void>([
      postManager.refreshPosts(),
      recruitmentManager.refreshRecruitments(),
    ]);
  }

  bool get isLoadingPosts => postManager.isLoadingPosts;
  bool get isLoadingRecruitments =>
      recruitmentManager.isLoadingRecruitments;
  bool get isSubmittingPost => postManager.isSubmittingPost;

  List<CommunityPost> get posts => postManager.posts;
  List<RecruitmentPost> get recruitmentPosts =>
      recruitmentManager.recruitmentPosts;

  String? get postError => postManager.postError;
  String? get recruitmentError => recruitmentManager.recruitmentError;

  bool isJoining(String recruitmentId) =>
      recruitmentManager.isJoining(recruitmentId);
  bool isLikingPost(String postId) => postManager.isLikingPost(postId);
  bool isLoadingComments(String postId) =>
      postManager.isLoadingComments(postId);
  bool isSubmittingComment(String postId) =>
      postManager.isSubmittingComment(postId);
  List<PostComment> commentsFor(String postId) =>
      postManager.commentsFor(postId);

  Future<void> refreshPosts() => postManager.refreshPosts();
  Future<void> refreshRecruitments() =>
      recruitmentManager.refreshRecruitments();

  Future<void> createPost({
    required String content,
    List<File> images = const [],
  }) async {
    await postManager.createPost(content: content, images: images);
  }

  Future<void> toggleLike(String postId) => postManager.toggleLike(postId);

  Future<void> loadComments(String postId, {bool forceRefresh = false}) =>
      postManager.loadComments(postId, forceRefresh: forceRefresh);

  Future<void> addComment(String postId, String content) =>
      postManager.addComment(postId, content);

  Future<void> joinRecruitment(String recruitmentId) =>
      recruitmentManager.joinRecruitment(recruitmentId);

  void _propagateChanges() {
    if (_isDisposed) {
      return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    postManager.removeListener(_postManagerListener);
    recruitmentManager.removeListener(_recruitmentManagerListener);
    postManager.dispose();
    recruitmentManager.dispose();
    super.dispose();
  }
}
