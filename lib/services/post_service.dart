import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:pocketbase/pocketbase.dart';

import '../models/post.dart';
import 'pocketbase_client.dart';

class PostServiceException implements Exception {
  PostServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PostService {
  static const String collection = 'posts';

  Future<List<Post>> fetchPosts({
    int page = 1,
    int perPage = 20,
  }) async {
    final client = await getPocketbaseInstance();

    try {
      final result = await client.collection(collection).getList(
            page: page,
            perPage: perPage,
            filter: "is_active = true",
            sort: '-created',
            expand: 'author',
          );

      return result.items
          .map((record) => Post.fromRecord(client, record))
          .toList(growable: false);
    } on ClientException catch (error) {
      throw PostServiceException(_mapClientError(error));
    } catch (_) {
      throw PostServiceException(
        'Không thể tải danh sách bài viết. Vui lòng thử lại sau.',
      );
    }
  }

  Future<Post> createPost({
    required String content,
    List<File> imageFiles = const <File>[],
  }) async {
    final client = await getPocketbaseInstance();
    final authorId = client.authStore.record?.id;

    if (authorId == null || authorId.isEmpty) {
      throw PostServiceException('Bạn cần đăng nhập trước khi đăng bài.');
    }

    try {
      final files = await _buildMultipartFiles(imageFiles);

      final record = await client.collection(collection).create(
        body: {
          'content': content.trim(),
          'author': authorId,
          'is_active': true,
        },
        files: files,
      );

      if (record.expand == null || record.expand!.isEmpty) {
        final refreshed = await client.collection(collection).getOne(
              record.id,
              expand: 'author',
            );
        return Post.fromRecord(client, refreshed);
      }

      return Post.fromRecord(client, record);
    } on ClientException catch (error) {
      throw PostServiceException(_mapClientError(error));
    } catch (error) {
      throw PostServiceException(
        'Đăng bài thất bại. Vui lòng thử lại. Lỗi: $error',
      );
    }
  }

  Future<List<http.MultipartFile>> _buildMultipartFiles(List<File> files) async {
    final result = <http.MultipartFile>[];

    for (final file in files) {
      if (!await file.exists()) {
        continue;
      }
      final bytes = await file.readAsBytes();
      final fileName = p.basename(file.path);
      result.add(
        http.MultipartFile.fromBytes(
          'images',
          bytes,
          filename: fileName,
        ),
      );
    }

    return result;
  }

  String _mapClientError(ClientException error) {
    if (error.response['message'] is String) {
      return error.response['message'] as String;
    }
    if (error.statusCode == 401) {
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    }
    if (error.statusCode == 403) {
      return 'Bạn không có quyền thực hiện thao tác này.';
    }
    return 'Có lỗi xảy ra. Mã lỗi: ${error.statusCode ?? 'không xác định'}';
  }
}
