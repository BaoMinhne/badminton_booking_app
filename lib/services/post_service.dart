import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:pocketbase/pocketbase.dart';

import '../models/community_post.dart';
import '../models/post_comment.dart';
import 'pocketbase_client.dart';

class PostServiceException implements Exception {
  PostServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PostService {
  static const String postsCollection = 'posts';
  static const String postLikesCollection = 'post_likes';
  static const String postCommentsCollection = 'post_comments';

  Future<List<CommunityPost>> fetchPosts({
    int page = 1,
    int perPage = 20,
  }) async {
    final pocketBase = await getPocketbaseInstance();
    try {
      final result = await pocketBase.collection(postsCollection).getList(
            page: page,
            perPage: perPage,
            sort: '-created',
            expand: 'author',
            filter: "is_active = true",
          );

      final posts = result.items
          .map((record) => CommunityPost.fromRecord(record, pocketBase))
          .toList(growable: false);

      final updatedPosts = await Future.wait(
        posts.map((post) => _attachPostMeta(post, pocketBase)),
        eagerError: false,
      );

      return updatedPosts;
    } on ClientException catch (error) {
      throw PostServiceException(_mapClientError(error));
    } catch (_) {
      throw PostServiceException(
        'Không thể tải bài viết. Vui lòng thử lại sau.',
      );
    }
  }

  Future<CommunityPost> createPost({
    required String content,
    List<File> images = const [],
  }) async {
    final pocketBase = await getPocketbaseInstance();
    final currentUserId = pocketBase.authStore.record?.id;
    if (currentUserId == null) {
      throw PostServiceException('Bạn cần đăng nhập để đăng bài viết.');
    }

    if (content.trim().isEmpty && images.isEmpty) {
      throw PostServiceException(
        'Vui lòng nhập nội dung hoặc chọn ít nhất một ảnh.',
      );
    }

    final files = <http.MultipartFile>[];
    for (final image in images) {
      final bytes = await image.readAsBytes();
      final filename = p.basename(image.path);
      files.add(
        http.MultipartFile.fromBytes(
          'images',
          bytes,
          filename: filename,
        ),
      );
    }

    try {
      final record = await pocketBase.collection(postsCollection).create(
        body: {
          'author': currentUserId,
          'content': content.trim(),
          'is_active': true,
        },
        files: files,
      );

      return CommunityPost.fromRecord(record, pocketBase);
    } on ClientException catch (error) {
      throw PostServiceException(_mapClientError(error));
    } catch (_) {
      throw PostServiceException('Đăng bài viết thất bại. Vui lòng thử lại.');
    }
  }

  Future<String> likePost(String postId) async {
    final pocketBase = await getPocketbaseInstance();
    final userId = pocketBase.authStore.record?.id;
    if (userId == null) {
      throw PostServiceException('Bạn cần đăng nhập để thích bài viết.');
    }

    final existing = await _findExistingLike(
      pocketBase,
      postId: postId,
      userId: userId,
    );
    if (existing != null) {
      return existing.id;
    }

    try {
      final record = await pocketBase.collection(postLikesCollection).create(
        body: {
          'post': postId,
          'user': userId,
        },
      );
      return record.id;
    } on ClientException catch (error) {
      throw PostServiceException(_mapClientError(error));
    } catch (_) {
      throw PostServiceException('Không thể thích bài viết.');
    }
  }

  Future<void> unlikePost({
    required String postId,
    String? likeRecordId,
  }) async {
    final pocketBase = await getPocketbaseInstance();
    final userId = pocketBase.authStore.record?.id;
    if (userId == null) {
      throw PostServiceException('Bạn cần đăng nhập để bỏ thích bài viết.');
    }

    final recordId = likeRecordId ??
        (await _findExistingLike(
          pocketBase,
          postId: postId,
          userId: userId,
        ))
            ?.id;

    if (recordId == null) {
      throw PostServiceException('Bạn chưa thích bài viết này.');
    }

    try {
      await pocketBase.collection(postLikesCollection).delete(recordId);
    } on ClientException catch (error) {
      throw PostServiceException(_mapClientError(error));
    } catch (_) {
      throw PostServiceException('Không thể bỏ thích bài viết.');
    }
  }

  Future<List<PostComment>> fetchComments(String postId) async {
    final pocketBase = await getPocketbaseInstance();
    try {
      final result =
          await pocketBase.collection(postCommentsCollection).getFullList(
                filter: 'post = "$postId"',
                expand: 'author',
                sort: 'created',
              );
      return result
          .map((record) => PostComment.fromRecord(record, pocketBase))
          .toList(growable: false);
    } on ClientException catch (error) {
      throw PostServiceException(_mapClientError(error));
    } catch (_) {
      throw PostServiceException('Không thể tải bình luận.');
    }
  }

  Future<CommunityPost?> fetchPostById(String id) async {
    final pocketBase = await getPocketbaseInstance();
    try {
      final record = await pocketBase.collection(postsCollection).getOne(
            id,
            expand: 'author',
          );
      return recordToCommunityPost(record, pocketBase);
    } on ClientException catch (error) {
      if (error.statusCode == 404) {
        return null;
      }
      throw PostServiceException(_mapClientError(error));
    } catch (_) {
      throw PostServiceException(
        'Không thể tải bài viết. Vui lòng thử lại sau.',
      );
    }
  }

  Future<CommunityPost> recordToCommunityPost(
    RecordModel record,
    PocketBase pocketBase,
  ) async {
    final post = CommunityPost.fromRecord(record, pocketBase);
    return _attachPostMeta(post, pocketBase);
  }

  Future<PostComment> createComment({
    required String postId,
    required String content,
  }) async {
    final pocketBase = await getPocketbaseInstance();
    final userId = pocketBase.authStore.record?.id;
    if (userId == null) {
      throw PostServiceException('Bạn cần đăng nhập để bình luận.');
    }

    if (content.trim().isEmpty) {
      throw PostServiceException('Vui lòng nhập nội dung bình luận.');
    }

    try {
      final record = await pocketBase.collection(postCommentsCollection).create(
        body: {
          'post': postId,
          'author': userId,
          'content': content.trim(),
        },
        expand: 'author',
      );
      return PostComment.fromRecord(record, pocketBase);
    } on ClientException catch (error) {
      throw PostServiceException(_mapClientError(error));
    } catch (_) {
      throw PostServiceException('Không thể gửi bình luận.');
    }
  }

  String _mapClientError(ClientException error) {
    if (error.response != null && error.response['message'] is String) {
      return error.response['message'] as String;
    }
    return 'Có lỗi xảy ra. Vui lòng thử lại.';
  }

  Future<CommunityPost> _attachPostMeta(
    CommunityPost post,
    PocketBase pocketBase,
  ) async {
    try {
      final userId = pocketBase.authStore.record?.id;

      final likesFuture = pocketBase.collection(postLikesCollection).getList(
            page: 1,
            perPage: userId != null ? 200 : 1,
            filter: 'post = "${post.id}"',
          );
      final commentsFuture =
          pocketBase.collection(postCommentsCollection).getList(
                page: 1,
                perPage: 1,
                filter: 'post = "${post.id}"',
              );

      final likesResult = await likesFuture;
      final commentsResult = await commentsFuture;

      bool isLiked = false;
      String? likeRecordId = post.likeRecordId;

      if (userId != null) {
        for (final like in likesResult.items) {
          final likeUser = like.data['user'];
          if (likeUser == userId) {
            isLiked = true;
            likeRecordId = like.id;
            break;
          }
        }

        if (!isLiked && likesResult.totalItems > likesResult.items.length) {
          final existing = await _findExistingLike(
            pocketBase,
            postId: post.id,
            userId: userId,
          );
          if (existing != null) {
            isLiked = true;
            likeRecordId = existing.id;
          }
        }
      }

      return post.copyWith(
        likesCount: likesResult.totalItems,
        isLiked: isLiked,
        likeRecordId: likeRecordId,
        commentsCount: commentsResult.totalItems,
      );
    } catch (_) {
      return post;
    }
  }

  Future<RecordModel?> _findExistingLike(
    PocketBase pocketBase, {
    required String postId,
    required String userId,
  }) async {
    try {
      final record =
          await pocketBase.collection(postLikesCollection).getFirstListItem(
                'post = "$postId" && user = "$userId"',
              );
      return record;
    } on ClientException catch (error) {
      if (error.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }
}
