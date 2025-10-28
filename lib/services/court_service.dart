import 'package:pocketbase/pocketbase.dart';

import '../models/court.dart';
import '../models/court_detail.dart';
import 'pocketbase_client.dart';

class CourtServiceException implements Exception {
  CourtServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CourtService {
  static const collection = 'courts';

  Future<List<Court>> listCourts({
    int page = 1,
    int perPage = 20,
    String? filter,
  }) async {
    final pb = await getPocketbaseInstance();

    try {
      final result = await pb.collection(collection).getList(
            page: page,
            perPage: perPage,
            filter: filter,
          );

      return result.items
          .map((record) => _mapRecordToCourt(pb, record))
          .toList(growable: false);
    } on ClientException catch (error) {
      throw CourtServiceException(
        _mapClientException(
          error,
          fallback: 'Không thể tải danh sách sân. Vui lòng thử lại sau.',
        ),
      );
    } catch (_) {
      throw CourtServiceException(
        'Có lỗi xảy ra khi tải danh sách sân. Vui lòng thử lại.',
      );
    }
  }

  Future<Court> getCourt(String id) async {
    final pb = await getPocketbaseInstance();

    try {
      final record = await pb.collection(collection).getOne(id);
      return _mapRecordToCourt(pb, record);
    } on ClientException catch (error) {
      throw CourtServiceException(
        _mapClientException(
          error,
          fallback: 'Không thể tải thông tin sân. Vui lòng thử lại.',
        ),
      );
    } catch (_) {
      throw CourtServiceException(
        'Đã xảy ra lỗi khi lấy thông tin sân. Vui lòng thử lại.',
      );
    }
  }

  Future<CourtDetailData> getCourtDetail(String id) async {
    final pb = await getPocketbaseInstance();
    final escapedId = _escapeFilterValue(id);

    try {
      final courtRecord = await pb.collection(collection).getOne(id);
      final court = _mapRecordToCourt(pb, courtRecord);

      final filter = "court_id='$escapedId'";

      final futures = <Future<ResultList<RecordModel>>>[
        pb.collection('court_images').getList(filter: filter, perPage: 100),
        pb
            .collection('court_opening_hours')
            .getList(filter: filter, perPage: 100),
        pb.collection('court_pricing').getList(filter: filter, perPage: 100),
        pb.collection('court_units').getList(filter: filter, perPage: 100),
        pb.collection('court_services').getList(
              filter: filter,
              perPage: 200,
              expand: 'service_id',
            ),
      ];

      final results = await Future.wait(futures);

      final imageResult = results[0];
      final openingHourResult = results[1];
      final pricingResult = results[2];
      final unitsResult = results[3];
      final servicesResult = results[4];

      final images = imageResult.items
          .expand((record) => _extractFileUrls(pb, record, 'image'))
          .toList(growable: false);

      final openingHours = openingHourResult.items
          .map(CourtOpeningHour.fromRecord)
          .toList(growable: false);

      final pricing = pricingResult.items
          .map(CourtPricing.fromRecord)
          .toList(growable: false);

      final units =
          unitsResult.items.map(CourtUnit.fromRecord).toList(growable: false);

      final services = servicesResult.items
          .map((record) {
            final serviceId = (record.data['service_id'] as String?)?.trim();
            if (serviceId == null || serviceId.isEmpty) {
              return null;
            }
            final catalog = _extractExpandedCatalog(record, serviceId);
            final item = CourtServiceItem.fromRecord(record, catalog: catalog);
            return item.name.trim().isEmpty ? null : item;
          })
          .whereType<CourtServiceItem>()
          .where((item) => item.isActive)
          .toList(growable: false);

      return CourtDetailData(
        court: court,
        images: images,
        openingHours: openingHours,
        pricing: pricing,
        units: units,
        services: services,
      );
    } on ClientException catch (error) {
      throw CourtServiceException(
        _mapClientException(
          error,
          fallback:
              'Không thể tải thông tin chi tiết của sân. Vui lòng thử lại sau.',
        ),
      );
    } catch (_) {
      throw CourtServiceException(
        'Có lỗi xảy ra khi tải thông tin chi tiết của sân. Vui lòng thử lại.',
      );
    }
  }

  ServiceCatalogItem? _extractExpandedCatalog(
    RecordModel record,
    String serviceId,
  ) {
    final expand = record.expand;
    if (expand == null || expand.isEmpty) {
      return null;
    }

    final expanded = expand['service_id'];

    if (expanded is RecordModel) {
      return ServiceCatalogItem.fromRecord(expanded as RecordModel);
    }

    if (expanded is List) {
      for (final item in expanded!) {
        if (item is RecordModel) {
          if (item.id == serviceId || expanded.length == 1) {
            return ServiceCatalogItem.fromRecord(item);
          }
        }
      }
    }

    return null;
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

  String _mapClientException(
    ClientException error, {
    required String fallback,
  }) {
    if (error.statusCode == 401 || error.statusCode == 403) {
      return 'Phiên đăng nhập đã hết hạn hoặc bạn không có quyền truy cập dữ liệu này. '
          'Vui lòng đăng nhập lại để tiếp tục.';
    }

    final response = error.response;
    if (response is Map<String, dynamic>) {
      final message = response['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }

      final data = response['data'];
      if (data is Map<String, dynamic>) {
        final buffer = StringBuffer();
        data.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            final detail = value['message'];
            if (detail is String && detail.trim().isNotEmpty) {
              if (buffer.isNotEmpty) buffer.writeln();
              buffer.write(detail.trim());
            }
          }
        });

        if (buffer.isNotEmpty) {
          return buffer.toString();
        }
      }
    }

    final rawMessage = error.toString();
    final colonIndex = rawMessage.indexOf(':');
    if (colonIndex != -1 && colonIndex + 1 < rawMessage.length) {
      final candidate = rawMessage.substring(colonIndex + 1).trim();
      if (candidate.isNotEmpty) {
        return candidate;
      }
    }

    return fallback;
  }
}
