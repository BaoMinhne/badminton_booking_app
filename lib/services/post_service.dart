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
  static const collection = 'posts';

  Future<List<CommunityPost>> fetchPosts({
    int page = 1,
    int perPage = 20,
  }) async {
    final pocketBase = await getPocketbaseInstance();

    try {
      final result = await pocketBase.collection(collection).getList(
            page: page,
            perPage: perPage,
            filter: "is_active = true",
            expand: 'author',
            sort: '-created',
          );
      return result.items
          .map((record) => CommunityPost.fromRecord(record, pocketBase))
          .toList(growable: false);
    } on ClientException catch (error) {
      throw PostServiceException(_mapClientException(error));
    } catch (_) {
      throw PostServiceException('Không thể tải bài viết. Vui lòng thử lại.');
    }
  }

  Future<CommunityPost> createPost({
    required String authorId,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw PostServiceException('Nội dung bài viết không được để trống.');
    }

    final pocketBase = await getPocketbaseInstance();

    try {
      final record = await pocketBase.collection(collection).create(body: {
        'author': authorId,
        'content': trimmed,
        'is_active': true,
      });
      final fetched = await pocketBase.collection(collection).getOne(
            record.id,
            expand: 'author',
          );
      return CommunityPost.fromRecord(fetched, pocketBase);
    } on ClientException catch (error) {
      throw PostServiceException(_mapClientException(error));
    } catch (_) {
      throw PostServiceException('Không thể đăng bài viết. Vui lòng thử lại.');
    }
  }

  String _mapClientException(ClientException error) {
    final response = error.response;
    if (response is Map<String, dynamic>) {
      final message = response['message'] as String?;
      if (message != null && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    return 'Đã có lỗi xảy ra. Vui lòng thử lại.';
  }
}
