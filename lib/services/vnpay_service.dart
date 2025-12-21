import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class VnpayServiceException implements Exception {
  VnpayServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class VnpayPaymentSession {
  VnpayPaymentSession({
    required this.paymentUrl,
    required this.bookingId,
    this.paymentId,
    this.transactionRef,
  });

  final String paymentUrl;
  final String bookingId;
  final String? paymentId;
  final String? transactionRef;
}

class VnpayService {
  VnpayService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<VnpayPaymentSession> createPaymentSession({
    required String bookingId,
    required int amountMinor,
    required String currency,
    required String description,
    String? returnUrl,
  }) async {
    final baseUrl = dotenv.env['VNPAY_API_BASE_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      throw VnpayServiceException(
        'Thiếu cấu hình VNPAY_API_BASE_URL để tạo phiên thanh toán.',
      );
    }

    final createPath =
        dotenv.env['VNPAY_CREATE_PATH'] ?? '/vnpay/create-payment';
    final uri = Uri.parse(baseUrl).resolve(createPath);

    final body = <String, dynamic>{
      'bookingId': bookingId,
      'amountMinor': amountMinor,
      'currency': currency,
      'description': description,
      if (returnUrl != null && returnUrl.isNotEmpty) 'returnUrl': returnUrl,
    };

    http.Response response;
    try {
      response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    } catch (_) {
      throw VnpayServiceException(
        'Không thể kết nối tới máy chủ VNPAY. Vui lòng thử lại.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw VnpayServiceException(
        'Không thể tạo phiên thanh toán VNPAY (mã ${response.statusCode}).',
      );
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic>) {
      throw VnpayServiceException('Phản hồi VNPAY không hợp lệ.');
    }

    final paymentUrl = payload['paymentUrl'] as String?;
    if (paymentUrl == null || paymentUrl.isEmpty) {
      throw VnpayServiceException('Thiếu đường dẫn thanh toán VNPAY.');
    }

    return VnpayPaymentSession(
      paymentUrl: paymentUrl,
      bookingId: bookingId,
      paymentId: payload['paymentId'] as String?,
      transactionRef: payload['transactionRef'] as String?,
    );
  }
}
