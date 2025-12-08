import 'package:pocketbase/pocketbase.dart';

import '../models/court.dart';
import 'pocketbase_client.dart';

class FavoriteCourtService {
  static const collection = 'user_favorites';

  Future<Set<String>> getFavoriteCourtIds(String userId) async {
    final pb = await getPocketbaseInstance();
    final result = await pb.collection(collection).getList(
          filter: "user_id='$userId'",
          perPage: 200,
        );

    return result.items
        .map((item) => item.data['court_id']?.toString())
        .whereType<String>()
        .toSet();
  }

  Future<void> addFavorite(String userId, Court court) async {
    final pb = await getPocketbaseInstance();
    try {
      await pb.collection(collection).create(body: {
        'user_id': userId,
        'court_id': court.id,
      });
    } on ClientException catch (error) {
      // Ignore conflict when the favorite already exists
      if ((error.response['code'] as int?) != 400) rethrow;
    }
  }

  Future<void> removeFavorite(String userId, String courtId) async {
    final pb = await getPocketbaseInstance();
    try {
      final first = await pb
          .collection(collection)
          .getFirstListItem("user_id='$userId' && court_id='$courtId'");
      await pb.collection(collection).delete(first.id);
    } on ClientException catch (error) {
      if ((error.response['code'] as int?) != 404) rethrow;
    }
  }
}
