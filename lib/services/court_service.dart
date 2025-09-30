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

  Future<CourtDetailData> getCourtDetail(String id) async {
    final pb = await getPocketbaseInstance();
    final escapedId = _escapeFilterValue(id);

    final courtRecord = await pb.collection(collection).getOne(id);
    final court = _mapRecordToCourt(pb, courtRecord);

    final filter = "court_id='$escapedId'";

    final futures = <Future<ResultList<RecordModel>>>[
      pb.collection('court_images').getList(filter: filter, perPage: 100),
      pb.collection('court_opening_hours').getList(filter: filter, perPage: 100),
      pb.collection('court_pricing').getList(filter: filter, perPage: 100),
      pb.collection('court_units').getList(filter: filter, perPage: 100),
    ];

    final results = await Future.wait(futures);

    final imageResult = results[0];
    final openingHourResult = results[1];
    final pricingResult = results[2];
    final unitsResult = results[3];

    final images = imageResult.items
        .expand((record) => _extractFileUrls(pb, record, 'image'))
        .toList(growable: false);

    final openingHours = openingHourResult.items
        .map(CourtOpeningHour.fromRecord)
        .toList(growable: false);

    final pricing = pricingResult.items
        .map(CourtPricing.fromRecord)
        .toList(growable: false);

    final units = unitsResult.items
        .map(CourtUnit.fromRecord)
        .toList(growable: false);

    return CourtDetailData(
      court: court,
      images: images,
      openingHours: openingHours,
      pricing: pricing,
      units: units,
    );
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

  List<String> _extractFileUrls(
    PocketBase pb,
    RecordModel record,
    String field,
  ) {
    final value = record.data[field];
    final files = <String>[];

    if (value is String && value.isNotEmpty) {
      files.add(value);
    } else if (value is List) {
      for (final item in value) {
        if (item is String && item.isNotEmpty) {
          files.add(item);
        }
      }
    }

    return files
        .map((fileName) => pb.files.getUrl(record, fileName).toString())
        .toList(growable: false);
  }

  String _escapeFilterValue(String value) {
    return value.replaceAll("'", "\\'");
  }
}
