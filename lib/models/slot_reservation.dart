import 'package:flutter/foundation.dart';

/// Trạng thái đặt chỗ của một khung giờ trên sân.
enum SlotReservationStatus {
  /// Người dùng đang giữ chỗ tạm thời.
  holding,

  /// Người dùng đã xác nhận và đang chờ admin duyệt.
  awaitingApproval,

  /// Khung giờ đã được đặt cố định (không thể chọn).
  booked,

  /// Khung giờ đã bị khóa bởi quản lý.
  locked,

  /// Khung giờ đang được giữ bởi người dùng khác.
  heldByOthers,
}

/// Thông tin hiển thị cho một khung giờ đã giữ/đặt.
@immutable
class SlotReservationInfo {
  const SlotReservationInfo({
    required this.courtName,
    required this.courtIndex,
    required this.startHour,
    required this.status,
    required this.holdUntil,
  });

  final String courtName;
  final int courtIndex;
  final int startHour;
  final SlotReservationStatus status;
  final DateTime? holdUntil;

  SlotReservationInfo copyWith({
    SlotReservationStatus? status,
    DateTime? holdUntil,
  }) {
    return SlotReservationInfo(
      courtName: courtName,
      courtIndex: courtIndex,
      startHour: startHour,
      status: status ?? this.status,
      holdUntil: holdUntil ?? this.holdUntil,
    );
  }
}
