import 'package:pocketbase/pocketbase.dart';

RecordModel? resolveExpandedRecord(dynamic expanded) {
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

String sanitizeDisplayName(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return 'Người dùng';
  }
  return trimmed;
}

String? resolveFileUrl(
  PocketBase pocketBase,
  RecordModel? record,
  dynamic fileName,
) {
  if (record == null) {
    return null;
  }
  if (fileName is! String || fileName.isEmpty) {
    return null;
  }
  return pocketBase.files.getUrl(record, fileName).toString();
}
