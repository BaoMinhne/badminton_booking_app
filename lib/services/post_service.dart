import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:pocketbase/pocketbase.dart';

import '../models/community_post.dart';
import 'pocketbase_client.dart';

class PostServiceException implements Exception {
  PostServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PostService {
  static const String postsCollection = 'posts';

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

      return result.items
          .map((record) => CommunityPost.fromRecord(record, pocketBase))
          .toList(growable: false);
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
        files: files.isEmpty ? null : files,
      );

      return CommunityPost.fromRecord(record, pocketBase);
    } on ClientException catch (error) {
      throw PostServiceException(_mapClientError(error));
    } catch (_) {
      throw PostServiceException('Đăng bài viết thất bại. Vui lòng thử lại.');
    }
  }

  String _mapClientError(ClientException error) {
    if (error.response != null && error.response['message'] is String) {
      return error.response['message'] as String;
    }
    return 'Có lỗi xảy ra. Vui lòng thử lại.';
  }
}
