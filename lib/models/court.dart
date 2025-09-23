import 'package:pocketbase/pocketbase.dart';

class Court {
  final String id;
  final String name;
  final String code;
  final String location;
  final String? description;
  final int courtQuantity;
  final bool isActive;
  final String ownerId;
  final String? coverImage;
  final String? coverImageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Court({
    required this.id,
    required this.name,
    required this.code,
    required this.location,
    required this.courtQuantity,
    required this.isActive,
    required this.ownerId,
    this.description,
    this.coverImage,
    this.coverImageUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory Court.fromJson(
    Map<String, dynamic> json, {
    String? coverImageUrl,
  }) {
    final coverImageName = _parseCoverImage(json['cover_image']);

    return Court(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      location: json['location'] as String? ?? '',
      description: json['description'] as String?,
      courtQuantity: _parseInt(json['court_quantity']),
      isActive: _parseBool(json['is_active']),
      ownerId: _parseOwnerId(json),
      coverImage: coverImageName,
      coverImageUrl: coverImageUrl,
      createdAt: _parseDate(json['created']),
      updatedAt: _parseDate(json['updated']),
    );
  }

  factory Court.fromRecord(
    RecordModel record, {
    String? coverImageUrl,
  }) {
    return Court.fromJson(
      record.toJson(),
      coverImageUrl: coverImageUrl,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true') return true;
      if (lower == 'false') return false;
      final numValue = num.tryParse(value);
      if (numValue != null) {
        return numValue != 0;
      }
    }
    return false;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static String? _parseCoverImage(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return value;
    }
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is String && first.isNotEmpty) {
        return first;
      }
    }
    return null;
  }

  static String _parseOwnerId(Map<String, dynamic> json) {
    final owner = json['owner_id'] ?? json['owner'];
    if (owner is String) {
      return owner;
    }
    if (owner is Map<String, dynamic>) {
      final id = owner['id'];
      if (id is String) {
        return id;
      }
    }
    return '';
  }
}
