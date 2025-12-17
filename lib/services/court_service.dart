import 'package:http/http.dart' as http;
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

class CourtImageFile {
  const CourtImageFile({
    required this.recordId,
    required this.fileName,
    required this.url,
    required this.recordFiles,
  });

  final String recordId;
  final String fileName;
  final String url;
  final List<String> recordFiles;
}

class CourtService {
  static const collection = 'courts';

  Future<List<ServiceCatalogItem>> listServiceCatalog({
    int page = 1,
    int perPage = 200,
    bool onlyActive = true,
  }) async {
    final pb = await getPocketbaseInstance();

    try {
      final filter = onlyActive ? "is_active=true" : null;
      final result = await pb.collection('service_catalog').getList(
            page: page,
            perPage: perPage,
            filter: filter,
          );

      return result.items
          .map(ServiceCatalogItem.fromRecord)
          .where((item) => item.name.trim().isNotEmpty)
          .toList(growable: false);
    } on ClientException catch (error) {
      throw CourtServiceException(
        _mapClientException(
          error,
          fallback: 'Không thể tải danh sách dịch vụ. Vui lòng thử lại.',
        ),
      );
    } catch (_) {
      throw CourtServiceException(
        'Có lỗi xảy ra khi tải danh sách dịch vụ. Vui lòng thử lại.',
      );
    }
  }

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

  Future<List<Court>> listOwnerCourts({
    int page = 1,
    int perPage = 50,
  }) async {
    final pb = await getPocketbaseInstance();
    final authRecord = pb.authStore.record;

    if (authRecord == null) {
      throw CourtServiceException(
        'Bạn cần đăng nhập để xem danh sách sân của mình.',
      );
    }

    final escapedOwner = _escapeFilterValue(authRecord.id);

    try {
      final result = await pb.collection(collection).getList(
            page: page,
            perPage: perPage,
            filter: "owner='$escapedOwner'",
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

  Future<List<CourtServiceItem>> listCourtServices(
    String courtId, {
    bool includeInactive = true,
  }) async {
    final pb = await getPocketbaseInstance();
    final escapedId = _escapeFilterValue(courtId);

    try {
      final filter = includeInactive
          ? "court_id='$escapedId'"
          : "court_id='$escapedId' && is_active=true";

      final result = await pb.collection('court_services').getList(
            filter: filter,
            perPage: 200,
            expand: 'service_id',
          );

      return result.items
          .map(
            (record) => CourtServiceItem.fromRecord(
              record,
              catalog: _extractExpandedCatalog(
                record,
                (record.data['service_id'] as String?) ?? '',
              ),
            ),
          )
          .where((item) => includeInactive || item.isActive)
          .toList(growable: false);
    } on ClientException catch (error) {
      throw CourtServiceException(
        _mapClientException(
          error,
          fallback: 'Không thể tải danh sách dịch vụ của sân. Vui lòng thử lại.',
        ),
      );
    } catch (_) {
      throw CourtServiceException(
        'Có lỗi xảy ra khi tải danh sách dịch vụ của sân. Vui lòng thử lại.',
      );
    }
  }

  Future<List<CourtPricing>> listCourtPricing(String courtId) async {
    final pb = await getPocketbaseInstance();
    final escapedId = _escapeFilterValue(courtId);

    try {
      final result = await pb.collection('court_pricing').getList(
            filter: "court_id='$escapedId'",
            perPage: 200,
          );

      return result.items
          .map(CourtPricing.fromRecord)
          .toList(growable: false);
    } on ClientException catch (error) {
      throw CourtServiceException(
        _mapClientException(
          error,
          fallback: 'Không thể tải bảng giá giờ chơi. Vui lòng thử lại.',
        ),
      );
    } catch (_) {
      throw CourtServiceException(
        'Có lỗi xảy ra khi tải bảng giá giờ chơi. Vui lòng thử lại.',
      );
    }
  }

  Future<CourtServiceItem> createCourtService({
    required String courtId,
    required String serviceId,
    int? price,
    String? note,
    String? unit,
    String? serviceName,
    bool isActive = true,
  }) async {
    final pb = await getPocketbaseInstance();

    try {
      final record = await pb.collection('court_services').create(body: {
        'court_id': courtId,
        'service_id': serviceId,
        'price': price,
        'note': note?.trim().isEmpty == true ? null : note?.trim(),
        'unit': unit?.trim().isEmpty == true ? null : unit?.trim(),
        'service_name': serviceName?.trim().isEmpty == true
            ? null
            : serviceName?.trim(),
        'is_active': isActive,
      });

      return CourtServiceItem.fromRecord(record);
    } on ClientException catch (error) {
      throw CourtServiceException(
        _mapClientException(
          error,
          fallback: 'Không thể thêm dịch vụ cho sân. Vui lòng thử lại.',
        ),
      );
    } catch (_) {
      throw CourtServiceException(
        'Có lỗi xảy ra khi thêm dịch vụ cho sân. Vui lòng thử lại.',
      );
    }
  }

  Future<CourtServiceItem> updateCourtService({
    required String id,
    int? price,
    String? note,
    String? unit,
    String? serviceName,
    bool? isActive,
  }) async {
    final pb = await getPocketbaseInstance();

    try {
      final record = await pb.collection('court_services').update(
        id,
        body: {
          'price': price,
          'note': note?.trim().isEmpty == true ? null : note?.trim(),
          'unit': unit?.trim().isEmpty == true ? null : unit?.trim(),
          'service_name': serviceName?.trim().isEmpty == true
              ? null
              : serviceName?.trim(),
          if (isActive != null) 'is_active': isActive,
        },
      );

      return CourtServiceItem.fromRecord(record);
    } on ClientException catch (error) {
      throw CourtServiceException(
        _mapClientException(
          error,
          fallback: 'Không thể cập nhật dịch vụ. Vui lòng thử lại.',
        ),
      );
    } catch (_) {
      throw CourtServiceException(
        'Có lỗi xảy ra khi cập nhật dịch vụ. Vui lòng thử lại.',
      );
    }
  }

  Future<CourtPricing> updateCourtPricing({
    required String id,
    required int pricePerHour,
    String? timeFrom,
    String? timeTo,
    String? priceLabel,
  }) async {
    final pb = await getPocketbaseInstance();

    try {
      final record = await pb.collection('court_pricing').update(
        id,
        body: {
          'price_per_hour': pricePerHour,
          if (timeFrom != null) 'time_from': timeFrom,
          if (timeTo != null) 'time_to': timeTo,
          if (priceLabel != null && priceLabel.trim().isNotEmpty)
            'price_label': priceLabel.trim(),
        },
      );

      return CourtPricing.fromRecord(record);
    } on ClientException catch (error) {
      throw CourtServiceException(
        _mapClientException(
          error,
          fallback: 'Không thể cập nhật giá giờ chơi. Vui lòng thử lại.',
        ),
      );
    } catch (_) {
      throw CourtServiceException(
        'Có lỗi xảy ra khi cập nhật giá giờ chơi. Vui lòng thử lại.',
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

  Future<Court> updateCourt({
    required String courtId,
    required String name,
    required String location,
    required String phone,
    required int courtQuantity,
    int? pricePerHour,
    bool isActive = true,
    String? description,
  }) async {
    final pb = await getPocketbaseInstance();
    try {
      final body = <String, dynamic>{
        'name': name.trim(),
        'location': location.trim(),
        'phone': phone.trim(),
        'court_quantity': courtQuantity,
        'is_active': isActive,
        'description': description?.trim().isEmpty == true
            ? null
            : description?.trim(),
      };

      if (pricePerHour != null) {
        body['price_per_hour'] = pricePerHour;
      }

      final record = await pb.collection(collection).update(
        courtId,
        body: body,
      );

      return _mapRecordToCourt(pb, record);
    } on ClientException catch (error) {
      throw CourtServiceException(
        _mapClientException(
          error,
          fallback: 'Không thể cập nhật thông tin sân. Vui lòng thử lại.',
        ),
      );
    } catch (_) {
      throw CourtServiceException(
        'Có lỗi xảy ra khi cập nhật thông tin sân. Vui lòng thử lại.',
      );
    }
  }

  Future<List<CourtImageFile>> listCourtImages(String courtId) async {
    final pb = await getPocketbaseInstance();
    final escapedId = _escapeFilterValue(courtId);

    try {
      final result = await pb.collection('court_images').getList(
            filter: "court_id='$escapedId'",
            perPage: 100,
          );

      final images = <CourtImageFile>[];

      for (final record in result.items) {
        final fileNames = _extractFileNames(record, 'image');

        for (final name in fileNames) {
          images.add(
            CourtImageFile(
              recordId: record.id,
              fileName: name,
              url: pb.files.getUrl(record, name).toString(),
              recordFiles: List.unmodifiable(fileNames),
            ),
          );
        }
      }

      return images;
    } on ClientException catch (error) {
      throw CourtServiceException(
        _mapClientException(
          error,
          fallback: 'Không thể tải hình ảnh sân. Vui lòng thử lại.',
        ),
      );
    } catch (_) {
      throw CourtServiceException(
        'Có lỗi xảy ra khi tải hình ảnh sân. Vui lòng thử lại.',
      );
    }
  }

  Future<void> uploadCourtImages({
    required String courtId,
    required List<http.MultipartFile> files,
  }) async {
    if (files.isEmpty) {
      throw CourtServiceException('Vui lòng chọn ít nhất một hình ảnh.');
    }

    final pb = await getPocketbaseInstance();

    try {
      await pb.collection('court_images').create(
        body: {'court_id': courtId},
        files: files,
      );
    } on ClientException catch (error) {
      throw CourtServiceException(
        _mapClientException(
          error,
          fallback: 'Không thể tải lên hình ảnh. Vui lòng thử lại.',
        ),
      );
    } catch (_) {
      throw CourtServiceException(
        'Có lỗi xảy ra khi tải lên hình ảnh. Vui lòng thử lại.',
      );
    }
  }

  Future<void> removeCourtImage({
    required String recordId,
    required String fileName,
  }) async {
    final pb = await getPocketbaseInstance();

    try {
      final record = await pb.collection('court_images').getOne(recordId);
      final fileNames = _extractFileNames(record, 'image');

      final remaining = fileNames.where((name) => name != fileName).toList();

      if (remaining.isEmpty) {
        await pb.collection('court_images').delete(recordId);
      } else {
        await pb.collection('court_images').update(
          recordId,
          body: {'image': remaining},
        );
      }
    } on ClientException catch (error) {
      throw CourtServiceException(
        _mapClientException(
          error,
          fallback: 'Không thể xóa hình ảnh. Vui lòng thử lại.',
        ),
      );
    } catch (_) {
      throw CourtServiceException(
        'Có lỗi xảy ra khi xóa hình ảnh. Vui lòng thử lại.',
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
    final files = _extractFileNames(record, field);

    return files
        .map((fileName) => pb.files.getUrl(record, fileName).toString())
        .toList(growable: false);
  }

  List<String> _extractFileNames(RecordModel record, String field) {
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

    return files;
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
