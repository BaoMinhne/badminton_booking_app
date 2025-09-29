import 'dart:collection';

import 'package:pocketbase/pocketbase.dart';

import '../models/court.dart';
import '../models/court_detail.dart';
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

  Future<CourtDetailData> getCourtDetails(String id) async {
    final pb = await getPocketbaseInstance();

    try {
      final courtRecord = await pb.collection(collection).getOne(id);
      final court = _mapRecordToCourt(pb, courtRecord);

      final imagesRecords = await pb.collection('court_images').getFullList(
            filter: 'court_id = "$id"',
            sort: '-created',
          );
      final openingHourRecords = await pb
          .collection('court_opening_hours')
          .getFullList(
            filter: 'court_id = "$id"',
            sort: 'open_time',
          );
      final pricingRecords = await pb.collection('court_pricing').getFullList(
            filter: 'court_id = "$id"',
            sort: 'time_from',
          );
      final unitRecords = await pb.collection('court_units').getFullList(
            filter: 'court_id = "$id"',
            sort: 'label',
          );

      final imageUrls = _extractImageUrls(
        pb,
        courtRecord,
        imagesRecords,
        court.coverImageUrl,
      );

      return CourtDetailData(
        court: court,
        images: imageUrls,
        openingHours: openingHourRecords
            .map(CourtOpeningHour.fromRecord)
            .toList(growable: false),
        pricing: pricingRecords
            .map(CourtPricing.fromRecord)
            .toList(growable: false),
        units: unitRecords
            .map(CourtUnit.fromRecord)
            .toList(growable: false),
      );
    } catch (e) {
      throw Exception('Không thể tải thông tin sân: $e');
    }
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

  List<String> _extractImageUrls(
    PocketBase pb,
    RecordModel courtRecord,
    List<RecordModel> imageRecords,
    String? coverImageUrl,
  ) {
    final urls = LinkedHashSet<String>();

    if (coverImageUrl != null && coverImageUrl.isNotEmpty) {
      urls.add(coverImageUrl);
    } else {
      final coverImageField = courtRecord.data['cover_image'];
      if (coverImageField is String && coverImageField.isNotEmpty) {
        urls.add(pb.files.getUrl(courtRecord, coverImageField).toString());
      } else if (coverImageField is List && coverImageField.isNotEmpty) {
        for (final item in coverImageField) {
          if (item is String && item.isNotEmpty) {
            urls.add(pb.files.getUrl(courtRecord, item).toString());
          }
        }
      }
    }

    for (final record in imageRecords) {
      final field = record.data['image'];
      if (field is String && field.isNotEmpty) {
        urls.add(pb.files.getUrl(record, field).toString());
      } else if (field is List) {
        for (final item in field) {
          if (item is String && item.isNotEmpty) {
            urls.add(pb.files.getUrl(record, item).toString());
          }
        }
      }
    }

    return urls.toList(growable: false);
  }
}
