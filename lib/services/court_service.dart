import 'package:pocketbase/pocketbase.dart';

import '../models/court.dart';
import 'pocketbase_client.dart';

class CourtService {
  static const collection = 'courts';

  Future<List<Court>> listCourts({
    int page = 1,
    int perPage = 20,
    String? filter,
  }) async {
    final pb = await getPocketbaseInstance();
    final result = await pb.collection(collection).getList(
          page: page,
          perPage: perPage,
          filter: filter,
        );

    return result.items
        .map((record) => _mapRecordToCourt(pb, record))
        .toList(growable: false);
  }

  Future<Court> getCourt(String id) async {
    final pb = await getPocketbaseInstance();
    final record = await pb.collection(collection).getOne(id);
    return _mapRecordToCourt(pb, record);
  }

  Court _mapRecordToCourt(PocketBase pb, RecordModel record) {
    final data = record.data;
    final coverImageField = data['cover_image'];
    String? coverImageName;

    if (coverImageField is String && coverImageField.isNotEmpty) {
      coverImageName = coverImageField;
    } else if (coverImageField is List && coverImageField.isNotEmpty) {
      final first = coverImageField.first;
      if (first is String && first.isNotEmpty) {
        coverImageName = first;
      }
    }

    final coverImageUrl = (coverImageName == null || coverImageName.isEmpty)
        ? null
        : pb.files.getUrl(record, coverImageName).toString();

    return Court.fromRecord(
      record,
      coverImageUrl: coverImageUrl,
    );
  }
}
