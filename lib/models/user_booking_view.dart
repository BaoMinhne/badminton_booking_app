import 'package:pocketbase/pocketbase.dart';

import 'booking.dart';

class UserBookingView {
  const UserBookingView({
    required this.booking,
    this.courtName,
    this.courtLocation,
    this.courtCoverImageUrl,
    this.courtUnitLabel,
  });

  factory UserBookingView.fromRecord(
    RecordModel record,
    PocketBase pocketBase,
  ) {
    final booking = CourtBooking.fromRecord(record);

    String? resolvedCourtName;
    String? resolvedCourtLocation;
    String? resolvedCourtCoverImageUrl;
    String? resolvedCourtUnitLabel;

    final expand = record.expand;
    if (expand != null && expand.isNotEmpty) {
      final courtRecord = _resolveExpandedRecord(expand['court_id']);
      if (courtRecord != null) {
        final data = courtRecord.data;
        final rawName = data['name'] as String?;
        final rawLocation = data['location'] as String?;
        resolvedCourtName = rawName?.trim().isNotEmpty == true
            ? rawName!.trim()
            : null;
        resolvedCourtLocation = rawLocation?.trim().isNotEmpty == true
            ? rawLocation!.trim()
            : null;

        final coverField = data['cover_image'];
        final coverFileName = _extractFirstFileName(coverField);
        if (coverFileName != null && coverFileName.isNotEmpty) {
          resolvedCourtCoverImageUrl =
              pocketBase.files.getUrl(courtRecord, coverFileName).toString();
        }
      }

      final courtUnitRecord = _resolveExpandedRecord(expand['court_unit_id']);
      if (courtUnitRecord != null) {
        final data = courtUnitRecord.data;
        final rawLabel =
            (data['court_label'] ?? data['label']) as String? ?? '';
        final trimmedLabel = rawLabel.trim();
        if (trimmedLabel.isNotEmpty) {
          resolvedCourtUnitLabel = trimmedLabel;
        }
      }
    }

    return UserBookingView(
      booking: booking,
      courtName: resolvedCourtName,
      courtLocation: resolvedCourtLocation,
      courtCoverImageUrl: resolvedCourtCoverImageUrl,
      courtUnitLabel: resolvedCourtUnitLabel,
    );
  }

  final CourtBooking booking;
  final String? courtName;
  final String? courtLocation;
  final String? courtCoverImageUrl;
  final String? courtUnitLabel;
}

RecordModel? _resolveExpandedRecord(dynamic expanded) {
  if (expanded is RecordModel) {
    return expanded;
  }

  if (expanded is List) {
    for (final item in expanded) {
      if (item is RecordModel) {
        return item;
      }
    }
  }

  return null;
}

String? _extractFirstFileName(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }

  if (value is List && value.isNotEmpty) {
    final first = value.first;
    if (first is String && first.trim().isNotEmpty) {
      return first.trim();
    }
  }

  return null;
}
