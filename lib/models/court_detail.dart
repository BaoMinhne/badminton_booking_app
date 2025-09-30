import 'package:pocketbase/pocketbase.dart';

import 'court.dart';

class CourtDetailData {
  final Court court;
  final List<String> images;
  final List<CourtOpeningHour> openingHours;
  final List<CourtPricing> pricing;
  final List<CourtUnit> units;

  const CourtDetailData({
    required this.court,
    this.images = const [],
    this.openingHours = const [],
    this.pricing = const [],
    this.units = const [],
  });
}

class CourtOpeningHour {
  final String id;
  final String openTime;
  final String closeTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CourtOpeningHour({
    required this.id,
    required this.openTime,
    required this.closeTime,
    this.createdAt,
    this.updatedAt,
  });

  factory CourtOpeningHour.fromRecord(RecordModel record) {
    final data = record.data;
    return CourtOpeningHour(
      id: record.id,
      openTime: (data['open_time'] as String?)?.trim() ?? '',
      closeTime: (data['close_time'] as String?)?.trim() ?? '',
      createdAt: _parseDate(data['created']),
      updatedAt: _parseDate(data['updated']),
    );
  }
}

class CourtPricing {
  final String id;
  final String? timeFrom;
  final String? timeTo;
  final int? pricePerHour;
  final String? priceLabel;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CourtPricing({
    required this.id,
    this.timeFrom,
    this.timeTo,
    this.pricePerHour,
    this.priceLabel,
    this.createdAt,
    this.updatedAt,
  });

  factory CourtPricing.fromRecord(RecordModel record) {
    final data = record.data;
    final rawPrice = data['price_per_hour'];
    return CourtPricing(
      id: record.id,
      timeFrom: (data['time_from'] as String?)?.trim(),
      timeTo: (data['time_to'] as String?)?.trim(),
      pricePerHour: _parsePrice(rawPrice),
      priceLabel: _parsePrice(rawPrice) == null
          ? (rawPrice is String && rawPrice.trim().isNotEmpty
              ? rawPrice.trim()
              : null)
          : null,
      createdAt: _parseDate(data['created']),
      updatedAt: _parseDate(data['updated']),
    );
  }
}

class CourtUnit {
  final String id;
  final String label;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CourtUnit({
    required this.id,
    required this.label,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory CourtUnit.fromRecord(RecordModel record) {
    final data = record.data;
    return CourtUnit(
      id: record.id,
      label: (data['label'] as String?)?.trim() ?? '',
      isActive: _parseBool(data['is_active']),
      createdAt: _parseDate(data['created']),
      updatedAt: _parseDate(data['updated']),
    );
  }
}

bool _parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.trim().toLowerCase();
    if (v == 'true') return true;
    if (v == 'false') return false;
    final parsed = num.tryParse(v);
    if (parsed != null) return parsed != 0;
  }
  return false;
}

DateTime? _parseDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

int? _parsePrice(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }
  return null;
}
