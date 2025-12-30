import 'package:badminton_booking_app/models/booking.dart';
import 'package:badminton_booking_app/pages/court/booking_manager.dart';
import 'package:badminton_booking_app/services/stripe_payment_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';

class PaymentSheetPage extends StatefulWidget {
  const PaymentSheetPage({
    super.key,
    required this.bookings,
  });

  final List<CourtBooking> bookings;

  @override
  State<PaymentSheetPage> createState() => _PaymentSheetPageState();
}

class _PaymentSheetPageState extends State<PaymentSheetPage> {
  final StripePaymentService _stripePaymentService = StripePaymentService();
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startPayment();
  }

  Future<void> _startPayment() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final provider = context.read<BookingManager>();
      final bookings = widget.bookings;
      final amountMinor = provider.calculateTotalAmount(bookings);
      final serviceCharges = provider.selectedServiceCharges;
      if ((bookings.isEmpty && serviceCharges.isEmpty) || amountMinor <= 0) {
        throw BookingManagerException(
          'No pending bookings or services to pay.',
        );
      }

      final intent = await _stripePaymentService.createPaymentIntent(
        currency: 'vnd',
        bookings: bookings
            .map(
              (booking) => StripeBookingPayment(
                bookingId: booking.id,
                amountMinor: provider.calculateBookingAmount(booking),
              ),
            )
            .toList(),
        services: serviceCharges
            .map(
              (service) => StripeServicePayment(
                serviceId: service.serviceId,
                quantity: service.quantity,
                amountMinor: service.totalAmount,
              ),
            )
            .toList(),
      );

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: intent.clientSecret,
          merchantDisplayName: 'Badminton Booking',
        ),
      );
      await Stripe.instance.presentPaymentSheet();

      await _stripePaymentService.confirmPaymentIntent(
        paymentIntentId: intent.paymentIntentId,
      );

      await provider.loadBookings(forceRefresh: true);
      provider.clearSelectedServices();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on StripePaymentException catch (error) {
      _setError(error.message);
    } on StripeException catch (error) {
      _setError(error.error.localizedMessage ?? 'Payment failed');
    } on BookingManagerException catch (error) {
      _setError(error.message);
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _errorMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isProcessing) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Opening payment sheet...'),
              ] else if (_errorMessage != null) ...[
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _startPayment,
                  child: const Text('Try again'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
              ] else ...[
                const SizedBox.shrink(),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
