import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class StripePaymentException implements Exception {
  StripePaymentException(this.message);

  final String message;

  @override
  String toString() => message;
}

class StripePaymentIntent {
  StripePaymentIntent({
    required this.clientSecret,
    required this.paymentIntentId,
  });

  final String clientSecret;
  final String paymentIntentId;
}

class StripeBookingPayment {
  StripeBookingPayment({
    required this.bookingId,
    required this.amountMinor,
  });

  final String bookingId;
  final int amountMinor;

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'amount_minor': amountMinor,
    };
  }
}

class StripePaymentService {
  Future<StripePaymentIntent> createPaymentIntent({
    required String currency,
    required List<StripeBookingPayment> bookings,
  }) async {
    final endpoint = dotenv.env['STRIPE_PAYMENT_INTENT_URL'];
    if (endpoint == null || endpoint.isEmpty) {
      throw StripePaymentException(
        'Missing STRIPE_PAYMENT_INTENT_URL in .env.',
      );
    }

    final uri = Uri.parse(endpoint);
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'currency': currency,
          'bookings': bookings.map((booking) => booking.toJson()).toList(),
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StripePaymentException(
          'Stripe payment intent failed (${response.statusCode}).',
        );
      }

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        throw StripePaymentException('Unexpected response from payment server.');
      }

      final clientSecret = data['client_secret'];
      final paymentIntentId = data['payment_intent_id'];
      if (clientSecret is! String || paymentIntentId is! String) {
        throw StripePaymentException('Invalid payment intent response.');
      }

      return StripePaymentIntent(
        clientSecret: clientSecret,
        paymentIntentId: paymentIntentId,
      );
    } catch (error) {
      if (error is StripePaymentException) {
        rethrow;
      }
      throw StripePaymentException(
        'Unable to create Stripe payment intent.',
      );
    }
  }
}
