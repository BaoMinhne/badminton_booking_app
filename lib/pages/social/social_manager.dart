import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../models/post.dart';
import '../../models/recruitment_post.dart';
import '../../services/post_service.dart';
import '../../services/recruitment_service.dart';

class SocialFeedManager with ChangeNotifier {
  SocialFeedManager({
    PostService? postService,
    RecruitmentService? recruitmentService,
  })  : _postService = postService ?? PostService(),
        _recruitmentService = recruitmentService ?? RecruitmentService();

  final PostService _postService;
  final RecruitmentService _recruitmentService;

  final List<Post> _posts = [];
  final List<RecruitmentPost> _recruitmentPosts = [];

  bool _isLoadingPosts = false;
  bool _isLoadingRecruitments = false;

  List<Post> get posts => List.unmodifiable(_posts);

  List<RecruitmentPost> get recruitmentPosts =>
      List.unmodifiable(_recruitmentPosts);

  bool get isLoadingPosts => _isLoadingPosts;

  bool get isLoadingRecruitments => _isLoadingRecruitments;

  Future<void> loadPosts() async {
    if (_isLoadingPosts) return;
    _isLoadingPosts = true;
    notifyListeners();

    try {
      final items = await _postService.fetchPosts();
      _posts
        ..clear()
        ..addAll(items);
    } finally {
      _isLoadingPosts = false;
      notifyListeners();
    }
  }

  Future<void> loadRecruitmentPosts() async {
    if (_isLoadingRecruitments) return;
    _isLoadingRecruitments = true;
    notifyListeners();

    try {
      final items = await _recruitmentService.fetchRecruitmentPosts();
      _recruitmentPosts
        ..clear()
        ..addAll(items);
    } finally {
      _isLoadingRecruitments = false;
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      loadPosts(),
      loadRecruitmentPosts(),
    ]);
  }

  Future<Post> createPost({
    required String content,
    List<File> imageFiles = const <File>[],
  }) async {
    final post = await _postService.createPost(
      content: content,
      imageFiles: imageFiles,
    );
    _posts.insert(0, post);
    notifyListeners();
    return post;
  }

  Future<RecruitmentPost> createRecruitmentPost({
    required String content,
    required int requiredMembers,
    String? courtId,
    DateTime? eventTime,
    String? skillLevel,
    String? playStyle,
    String? locationNote,
  }) async {
    final post = await _recruitmentService.createRecruitmentPost(
      content: content,
      requiredMembers: requiredMembers,
      courtId: courtId,
      eventTime: eventTime,
      skillLevel: skillLevel,
      playStyle: playStyle,
      locationNote: locationNote,
    );
    _recruitmentPosts.insert(0, post);
    notifyListeners();
    return post;
  }
}
