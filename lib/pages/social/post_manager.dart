import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../models/community_post.dart';
import '../../models/post_comment.dart';
import '../../services/post_service.dart';
import '../../services/pocketbase_client.dart';

class PostManager extends ChangeNotifier {
  PostManager() : _postService = PostService() {
    _initializeRealtime();
  }

  final PostService _postService;

  bool _isDisposed = false;
  bool _isLoadingPosts = false;
  bool _isSubmittingPost = false;

  List<CommunityPost> _posts = const [];
  String? _postError;

  final Set<String> _likingPosts = <String>{};
  final Set<String> _loadingComments = <String>{};
  final Set<String> _submittingComments = <String>{};
  final Set<String> _loadedComments = <String>{};
  final Map<String, List<PostComment>> _postComments =
      <String, List<PostComment>>{};

  UnsubscribeFunc? _postsUnsubscribe;
  UnsubscribeFunc? _likesUnsubscribe;
  UnsubscribeFunc? _commentsUnsubscribe;

  bool get isLoadingPosts => _isLoadingPosts;
  bool get isSubmittingPost => _isSubmittingPost;

  List<CommunityPost> get posts => _posts;
  String? get postError => _postError;

  bool isLikingPost(String postId) => _likingPosts.contains(postId);
  bool isLoadingComments(String postId) => _loadingComments.contains(postId);
  bool isSubmittingComment(String postId) =>
      _submittingComments.contains(postId);
  List<PostComment> commentsFor(String postId) =>
      _postComments[postId] ?? const <PostComment>[];

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
        final updated =
            post.copyWith(commentsCount: post.commentsCount + 1);
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

  void _initializeRealtime() {
    unawaited(_setupPostsRealtime());
    unawaited(_setupLikesRealtime());
    unawaited(_setupCommentsRealtime());
  }

  Future<void> _setupPostsRealtime() async {
    try {
      final pocketBase = await getPocketbaseInstance();

      final oldUnsub = _postsUnsubscribe;
      _postsUnsubscribe = null;
      if (oldUnsub != null) {
        await oldUnsub();
      }

      _postsUnsubscribe =
          await pocketBase.collection(PostService.postsCollection).subscribe(
                '*',
                _handlePostRealtimeEvent,
                expand: 'author',
              );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to initialize posts realtime subscription: $error');
        debugPrint(stackTrace.toString());
      }
    }
  }

  Future<void> _setupLikesRealtime() async {
    try {
      final pocketBase = await getPocketbaseInstance();

      final oldUnsub = _likesUnsubscribe;
      _likesUnsubscribe = null;
      if (oldUnsub != null) {
        await oldUnsub();
      }

      _likesUnsubscribe = await pocketBase
          .collection(PostService.postLikesCollection)
          .subscribe('*', _handlePostLikeEvent);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to initialize likes realtime subscription: $error');
        debugPrint(stackTrace.toString());
      }
    }
  }

  Future<void> _setupCommentsRealtime() async {
    try {
      final pocketBase = await getPocketbaseInstance();

      final oldUnsub = _commentsUnsubscribe;
      _commentsUnsubscribe = null;
      if (oldUnsub != null) {
        await oldUnsub();
      }

      _commentsUnsubscribe = await pocketBase
          .collection(PostService.postCommentsCollection)
          .subscribe(
        '*',
        _handlePostCommentEvent,
        expand: 'author',
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
            'Failed to initialize comments realtime subscription: $error');
        debugPrint(stackTrace.toString());
      }
    }
  }

  Future<void> _handlePostRealtimeEvent(
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
        debugPrint('Failed to process post realtime event: $error');
        debugPrint(stackTrace.toString());
      }
    } finally {
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  Future<void> _handlePostLikeEvent(RecordSubscriptionEvent event) async {
    if (_isDisposed) {
      return;
    }

    final record = event.record;
    if (record == null) {
      return;
    }

    final postId = _extractRelationId(record, 'post');
    if (postId == null) {
      return;
    }

    final index = _posts.indexWhere((post) => post.id == postId);
    if (index == -1) {
      return;
    }

    final post = _posts[index];

    try {
      final pocketBase = await getPocketbaseInstance();
      final currentUserId = pocketBase.authStore.record?.id;
      final likeUserId = _extractRelationId(record, 'user');

      switch (event.action) {
        case 'create':
          final updated = post.copyWith(
            likesCount: post.likesCount + 1,
            isLiked: currentUserId != null && currentUserId == likeUserId
                ? true
                : post.isLiked,
            likeRecordId:
                currentUserId != null && currentUserId == likeUserId
                    ? record.id
                    : post.likeRecordId,
          );
          _updatePostAt(index, updated);
          break;
        case 'delete':
          final newCount = post.likesCount > 0 ? post.likesCount - 1 : 0;
          final updated = post.copyWith(
            likesCount: newCount,
            isLiked: currentUserId != null && currentUserId == likeUserId
                ? false
                : post.isLiked,
            likeRecordId:
                currentUserId != null && currentUserId == likeUserId
                    ? null
                    : post.likeRecordId,
          );
          _updatePostAt(index, updated);
          break;
        default:
          break;
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to process like realtime event: $error');
        debugPrint(stackTrace.toString());
      }
    } finally {
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  Future<void> _handlePostCommentEvent(
    RecordSubscriptionEvent event,
  ) async {
    if (_isDisposed) {
      return;
    }

    final record = event.record;
    if (record == null) {
      return;
    }

    final postId = _extractRelationId(record, 'post');
    if (postId == null) {
      return;
    }

    final index = _posts.indexWhere((post) => post.id == postId);
    if (index == -1) {
      return;
    }

    final post = _posts[index];

    try {
      final pocketBase = await getPocketbaseInstance();
      final hasLoadedComments = _loadedComments.contains(postId);
      PostComment? updatedComment;
      if (event.action != 'delete') {
        updatedComment = PostComment.fromRecord(record, pocketBase);
      }

      switch (event.action) {
        case 'create':
          final newCount = post.commentsCount + 1;
          _updatePostAt(index, post.copyWith(commentsCount: newCount));
          if (hasLoadedComments && updatedComment != null) {
            final comments = List<PostComment>.from(commentsFor(postId))
              ..add(updatedComment);
            _postComments[postId] = comments;
          }
          break;
        case 'update':
          if (hasLoadedComments && updatedComment != null) {
            final comments = List<PostComment>.from(commentsFor(postId));
            final commentIndex =
                comments.indexWhere((comment) => comment.id == record.id);
            if (commentIndex != -1) {
              comments[commentIndex] = updatedComment;
              _postComments[postId] = comments;
            }
          }
          break;
        case 'delete':
          final newCount = post.commentsCount > 0
              ? post.commentsCount - 1
              : post.commentsCount;
          _updatePostAt(index, post.copyWith(commentsCount: newCount));
          if (hasLoadedComments) {
            final comments = List<PostComment>.from(commentsFor(postId))
              ..removeWhere((comment) => comment.id == record.id);
            _postComments[postId] = comments;
          }
          break;
        default:
          break;
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to process comment realtime event: $error');
        debugPrint(stackTrace.toString());
      }
    } finally {
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  void _updatePostAt(int index, CommunityPost updated) {
    final posts = List<CommunityPost>.from(_posts);
    posts[index] = updated;
    _posts = posts;
  }

  void _removePost(String postId) {
    final previousLength = _posts.length;
    _posts = _posts.where((post) => post.id != postId).toList(growable: false);
    if (previousLength != _posts.length) {
      _postComments.remove(postId);
    }
  }

  String? _extractRelationId(RecordModel record, String field) {
    final dataValue = record.data[field];
    if (dataValue is String && dataValue.isNotEmpty) {
      return dataValue;
    }

    final expanded = record.expand?[field];
    if (expanded is RecordModel) {
      return expanded.id;
    }
    if (expanded is List && expanded.isNotEmpty) {
      final first = expanded.first;
      if (first is RecordModel) {
        return first.id;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    final unsubList = [
      _postsUnsubscribe,
      _likesUnsubscribe,
      _commentsUnsubscribe,
    ];
    for (final unsub in unsubList) {
      if (unsub != null) {
        unawaited(unsub());
      }
    }
    _postsUnsubscribe = null;
    _likesUnsubscribe = null;
    _commentsUnsubscribe = null;
    super.dispose();
  }
}
