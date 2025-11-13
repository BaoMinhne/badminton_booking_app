import 'dart:async';
import 'dart:io';

import 'package:badminton_booking_app/services/pocketbase_client.dart';
import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../models/community_post.dart';
import '../../models/post_comment.dart';
import '../../models/recruitment_post.dart';
import '../../services/post_service.dart';
import '../../services/recruitment_service.dart';

class SocialManager with ChangeNotifier {
  SocialManager()
      : _postService = PostService(),
        _recruitmentService = RecruitmentService() {
    _initializeRealtime();
  }

  final PostService _postService;
  final RecruitmentService _recruitmentService;
  // use if RecordSubscription isn't present in your SDK
  UnsubscribeFunc? _postsUnsubscribe;
  bool _isDisposed = false;

  bool _isLoadingPosts = false;
  bool _isLoadingRecruitments = false;
  bool _isSubmittingPost = false;

  List<CommunityPost> _posts = const [];
  List<RecruitmentPost> _recruitmentPosts = const [];

  String? _postError;
  String? _recruitmentError;

  final Set<String> _joiningRecruitments = <String>{};
  final Set<String> _likingPosts = <String>{};
  final Set<String> _loadingComments = <String>{};
  final Set<String> _submittingComments = <String>{};
  final Set<String> _loadedComments = <String>{};
  final Map<String, List<PostComment>> _postComments =
      <String, List<PostComment>>{};

  bool get isLoadingPosts => _isLoadingPosts;
  bool get isLoadingRecruitments => _isLoadingRecruitments;
  bool get isSubmittingPost => _isSubmittingPost;

  List<CommunityPost> get posts => _posts;
  List<RecruitmentPost> get recruitmentPosts => _recruitmentPosts;

  String? get postError => _postError;
  String? get recruitmentError => _recruitmentError;

  bool isJoining(String recruitmentId) =>
      _joiningRecruitments.contains(recruitmentId);
  bool isLikingPost(String postId) => _likingPosts.contains(postId);
  bool isLoadingComments(String postId) => _loadingComments.contains(postId);
  bool isSubmittingComment(String postId) =>
      _submittingComments.contains(postId);
  List<PostComment> commentsFor(String postId) =>
      _postComments[postId] ?? const <PostComment>[];

  Future<void> loadInitial() async {
    await Future.wait<void>([
      refreshPosts(),
      refreshRecruitments(),
    ]);
  }

  void _initializeRealtime() {
    unawaited(_setupPostsRealtime());
  }

  Future<void> _setupPostsRealtime() async {
    try {
      final pocketBase = await getPocketbaseInstance();

      // Hủy subscription cũ (nếu có)
      final oldUnsub = _postsUnsubscribe;
      _postsUnsubscribe = null;
      if (oldUnsub != null) {
        await oldUnsub(); // gọi function
      }

      _postsUnsubscribe =
          await pocketBase.collection(PostService.postsCollection).subscribe(
                '*',
                _handlePostRealtimeEvent,
                expand: 'author', // string, không phải List
              );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to initialize posts realtime subscription: $error');
        debugPrint(stackTrace.toString());
      }
    }
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

  Future<void> toggleLike(String postId) async {
    final index = _posts.indexWhere((post) => post.id == postId);
    if (index == -1 || _likingPosts.contains(postId)) {
      return;
    }

    final post = _posts[index];
    _likingPosts.add(postId);
    notifyListeners();

    try {
      if (post.isLiked) {
        await _postService.unlikePost(
          postId: postId,
          likeRecordId: post.likeRecordId,
        );
        final newCount = post.likesCount > 0 ? post.likesCount - 1 : 0;
        final updated = post.copyWith(
          isLiked: false,
          likesCount: newCount,
          likeRecordId: null,
        );
        _updatePostAt(index, updated);
      } else {
        final likeRecordId = await _postService.likePost(postId);
        final updated = post.copyWith(
          isLiked: true,
          likesCount: post.likesCount + 1,
          likeRecordId: likeRecordId,
        );
        _updatePostAt(index, updated);
      }
    } on PostServiceException catch (error) {
      _postError = error.message;
      rethrow;
    } finally {
      _likingPosts.remove(postId);
      notifyListeners();
    }
  }

  Future<void> loadComments(String postId, {bool forceRefresh = false}) async {
    if (_loadingComments.contains(postId)) {
      return;
    }

    if (!forceRefresh && _loadedComments.contains(postId)) {
      return;
    }

    _loadingComments.add(postId);
    notifyListeners();

    try {
      final comments = await _postService.fetchComments(postId);
      _postComments[postId] = comments;
      _loadedComments.add(postId);
    } on PostServiceException catch (error) {
      _postError = error.message;
      rethrow;
    } finally {
      _loadingComments.remove(postId);
      notifyListeners();
    }
  }

  Future<void> addComment(String postId, String content) async {
    if (_submittingComments.contains(postId)) {
      return;
    }

    _submittingComments.add(postId);
    notifyListeners();

    try {
      final comment = await _postService.createComment(
        postId: postId,
        content: content,
      );

      final comments = List<PostComment>.from(commentsFor(postId))
        ..add(comment);
      _postComments[postId] = comments;

      final index = _posts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        final post = _posts[index];
        final updated = post.copyWith(commentsCount: post.commentsCount + 1);
        _updatePostAt(index, updated);
      }
    } on PostServiceException catch (error) {
      _postError = error.message;
      rethrow;
    } finally {
      _submittingComments.remove(postId);
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

  void _updatePostAt(int index, CommunityPost updated) {
    final posts = List<CommunityPost>.from(_posts);
    posts[index] = updated;
    _posts = posts;
  }

  Future<void> _handlePostRealtimeEvent(RecordSubscriptionEvent event) async {
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
          _removePost(record.id);
          break;
        case 'create':
        case 'update':
          final isActive = record.data['is_active'] != false;
          if (!isActive) {
            _removePost(record.id);
            break;
          }

          final pocketBase = await getPocketbaseInstance();
          final post =
              await _postService.recordToCommunityPost(record, pocketBase);
          final index = _posts.indexWhere((existing) => existing.id == post.id);
          if (index == -1) {
            _posts = [post, ..._posts];
          } else {
            _updatePostAt(index, post);
          }
          break;
        default:
          break;
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to process realtime event: $error');
        debugPrint(stackTrace.toString());
      }
    } finally {
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  void _removePost(String postId) {
    final previousLength = _posts.length;
    _posts = _posts.where((post) => post.id != postId).toList(growable: false);
    if (previousLength != _posts.length) {
      _postComments.remove(postId);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    final unsub = _postsUnsubscribe;
    _postsUnsubscribe = null;
    if (unsub != null) {
      unawaited(unsub()); // gọi function để unsubscribe
    }
    super.dispose();
  }
}
