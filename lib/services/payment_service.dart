import 'package:pocketbase/pocketbase.dart';

import 'pocketbase_client.dart';

class PaymentServiceException implements Exception {
  PaymentServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PaymentService {
  Future<RecordModel> createPayment({
    required String bookingId,
    required int amountMinor,
    required String currency,
    required String provider,
    required String status,
    String? transactionRef,
    String? payload,
  }) async {
    final pb = await getPocketbaseInstance();

    final body = <String, dynamic>{
      'booking_id': bookingId,
      'amount_minor': amountMinor,
      'currency': currency,
      'provider': provider,
      'status': status,
      if (transactionRef != null && transactionRef.isNotEmpty)
        'transaction_ref': transactionRef,
      if (payload != null && payload.isNotEmpty) 'payload': payload,
    };

    try {
      return await pb.collection('payment').create(body: body);
    } on ClientException catch (error) {
      throw PaymentServiceException(_mapClientException(error));
    } catch (_) {
      throw PaymentServiceException(
        'Không thể ghi nhận thanh toán. Vui lòng thử lại.',
      );
    }
  }

  Future<void> deletePayment(String id) async {
    final pb = await getPocketbaseInstance();
    try {
      await pb.collection('payment').delete(id);
    } on ClientException catch (error) {
      throw PaymentServiceException(_mapClientException(error));
    } catch (_) {
      throw PaymentServiceException('Không thể xoá giao dịch.');
    }
  }

  Future<String?> getLatestPaymentStatusForBooking({
    required String bookingId,
    required String provider,
  }) async {
    final pb = await getPocketbaseInstance();
    try {
      final result = await pb.collection('payment').getList(
            page: 1,
            perPage: 1,
            filter: 'booking_id = "$bookingId" && provider = "$provider"',
            sort: '-created',
          );
      if (result.items.isEmpty) {
        return null;
      }
      return result.items.first.data['status'] as String?;
    } on ClientException catch (error) {
      throw PaymentServiceException(_mapClientException(error));
    } catch (_) {
      throw PaymentServiceException('Không thể kiểm tra trạng thái thanh toán.');
    }
  }

  String _mapClientException(ClientException error) {
    if (error.response != null) {
      final data = error.response!['data'];
      if (data is Map && data.isNotEmpty) {
        final first = data.values.first;
        if (first is Map && first['message'] is String) {
          return first['message'] as String;
        }
      }
      if (error.response!['message'] is String) {
        return error.response!['message'] as String;
      }
    }
    return 'Đã xảy ra lỗi. Vui lòng thử lại.';
  }
}
