import 'package:pocketbase/pocketbase.dart';

class Court {
  static final RegExp _vnPhoneReg = RegExp(r'^(?:0|\+84)\d{9}$');

  final String id;
  final String name;
  final String code;

  final String phone;
  final String location;
  final String? description;
  final double? rating;
  final double? distanceKm;
  final int? pricePerHour;
  final String? nextSlotLabel;
  final int courtQuantity;
  final bool isActive;
  final String ownerId;
  final String? coverImage;
  final String? coverImageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int bookingCount;

  Court({
    required this.id,
    required this.name,
    required this.code,
    required this.phone,
    required this.location,
    required this.courtQuantity,
    required this.isActive,
    required this.ownerId,
    this.rating,
    this.distanceKm,
    this.pricePerHour,
    this.nextSlotLabel,
    this.description,
    this.coverImage,
    this.coverImageUrl,
    this.createdAt,
    this.updatedAt,
    this.bookingCount = 0,
  }) : assert(
          phone.isEmpty || _vnPhoneReg.hasMatch(phone),
          'phone không đúng định dạng VN (0xxxxxxxxx hoặc +84xxxxxxxxx)',
        );

  // ====== Factories ===========================================================
  factory Court.fromJson(
    Map<String, dynamic> json, {
    String? coverImageUrl,
  }) {
    final coverImageName = _parseCoverImage(json['cover_image']);
    final rawPhone = (json['phone'] as String? ?? '').trim();
    final normalized = _normalizePhone(rawPhone);

    return Court(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      phone: normalized,
      rating: _parseDouble(json['rating']),
      distanceKm: _parseDouble(json['distance_km']),
      pricePerHour: _parseInt(json['price_per_hour']),
      nextSlotLabel: json['next_slot_label'] as String?,
      location: json['location'] as String? ?? '',
      description: json['description'] as String?,
      courtQuantity: _parseInt(json['court_quantity']),
      isActive: _parseBool(json['is_active']),
      ownerId: _parseOwnerId(json),
      coverImage: coverImageName,
      coverImageUrl: coverImageUrl,
      createdAt: _parseDate(json['created']),
      updatedAt: _parseDate(json['updated']),
      bookingCount: _parseInt(json['booking_count']),
    );
  }

  factory Court.fromRecord(
    RecordModel record, {
    String? coverImageUrl,
  }) =>
      Court.fromJson(record.toJson(), coverImageUrl: coverImageUrl);

  // ====== Serialization =======================================================
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'phone': phone, // đã chuẩn hoá
        'location': location,
        'rating': rating,
        'distance_km': distanceKm,
        'price_per_hour': pricePerHour,
        'next_slot_label': nextSlotLabel,
        'description': description,
        'court_quantity': courtQuantity,
        'is_active': isActive,
        'owner_id': ownerId,
        'cover_image': coverImage,
        'booking_count': bookingCount,
        'created': createdAt?.toIso8601String(),
        'updated': updatedAt?.toIso8601String(),
      };

  // ====== Helpers for phone ===================================================
  /// Hợp lệ theo quy tắc VN?
  bool get isValidPhone => _vnPhoneReg.hasMatch(phone);

  /// Dạng hiển thị: 090 123 4567 hoặc +84 901 234 567
  String get phonePretty {
    final d = phoneDigits;
    if (phone.startsWith('+84')) {
      // +84xxxxxxxxx -> +84 90x xxx xxx
      return '+84 ${d.substring(2, 4)}${d.substring(4, 5)} ${d.substring(5, 8)} ${d.substring(8)}'
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }
    // 0xxxxxxxxx -> 090 123 4567
    return '${d.substring(0, 3)} ${d.substring(3, 6)} ${d.substring(6)}';
  }

  /// Chỉ phần số, luôn 0..9 và có 10 hoặc 11 ký tự nếu có +84.
  String get phoneDigits => phone.replaceAll(RegExp(r'[^\d+]'), '');

  /// Luôn trả về dạng local 0xxxxxxxxx.
  String get phoneLocal {
    final d = phoneDigits;
    if (phone.startsWith('+84')) {
      return '0${d.substring(3)}'; // +84xxxxxxxxx -> 0xxxxxxxxx
    }
    return phone;
  }

  /// Luôn trả về dạng quốc tế +84xxxxxxxxx.
  String get phoneE164 {
    final d = phoneDigits;
    if (phone.startsWith('+84')) return phone;
    // 0xxxxxxxxx -> +84xxxxxxxxx
    return '+84${d.substring(1)}';
  }

  // ====== Utils / copyWith / equality ========================================
  Court copyWith({
    String? id,
    String? name,
    String? code,
    String? phone,
    String? location,
    double? rating,
    double? distanceKm,
    int? pricePerHour,
    String? nextSlotLabel,
    String? description,
    int? courtQuantity,
    bool? isActive,
    String? ownerId,
    String? coverImage,
    String? coverImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? bookingCount,
  }) {
    final nextPhone = phone ?? this.phone;
    assert(
      nextPhone.isEmpty || _vnPhoneReg.hasMatch(nextPhone),
      'phone không đúng định dạng VN',
    );
    return Court(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      phone: _normalizePhone(nextPhone),
      location: location ?? this.location,
      rating: rating ?? this.rating,
      distanceKm: distanceKm ?? this.distanceKm,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      nextSlotLabel: nextSlotLabel ?? this.nextSlotLabel,
      description: description ?? this.description,
      courtQuantity: courtQuantity ?? this.courtQuantity,
      isActive: isActive ?? this.isActive,
      ownerId: ownerId ?? this.ownerId,
      coverImage: coverImage ?? this.coverImage,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bookingCount: bookingCount ?? this.bookingCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Court &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code &&
          phoneE164 == other.phoneE164;

  @override
  int get hashCode => Object.hash(id, code, phoneE164);

  // ====== Private parsing helpers ============================================
  static String _normalizePhone(String raw) {
    var phone = raw.replaceAll(RegExp(r'[\s\-\.\(\)]'), '');
    if (phone.startsWith('84') && phone.length == 11) phone = '+$phone';
    if (_vnPhoneReg.hasMatch(phone)) return phone;
    return phone;
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double? _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true') return true;
      if (lower == 'false') return false;
      final n = num.tryParse(value);
      if (n != null) return n != 0;
    }
    return false;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  static String? _parseCoverImage(dynamic value) {
    if (value is String && value.isNotEmpty) return value;
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is String && first.isNotEmpty) return first;
    }
    return null;
  }

  static String _parseOwnerId(Map<String, dynamic> json) {
    final owner = json['owner_id'] ?? json['owner'];
    if (owner is String) return owner;
    if (owner is Map<String, dynamic>) {
      final id = owner['id'];
      if (id is String) return id;
    }
    return '';
  }
}
