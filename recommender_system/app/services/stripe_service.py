import os

import json

import stripe


class StripeServiceError(Exception):
    def __init__(self, message: str) -> None:
        super().__init__(message)
        self.message = message


class StripeService:
    def __init__(self) -> None:
        secret_key = os.getenv("STRIPE_SECRET_KEY")
        if not secret_key:
            raise StripeServiceError("Missing STRIPE_SECRET_KEY.")
        stripe.api_key = secret_key

    def create_payment_intent(
        self,
        currency: str,
        bookings: list[dict],
    ) -> stripe.PaymentIntent:
        if not currency:
            raise StripeServiceError("Currency is required.")
        if not bookings:
            raise StripeServiceError("bookings must not be empty.")

        booking_ids = []
        booking_amounts = {}
        total_amount = 0
        for booking in bookings:
            booking_id = booking.get("booking_id")
            amount_minor = booking.get("amount_minor")
            if not booking_id or not isinstance(booking_id, str):
                raise StripeServiceError("booking_id is required.")
            if not isinstance(amount_minor, int) or amount_minor <= 0:
                raise StripeServiceError("amount_minor must be greater than 0.")
            booking_ids.append(booking_id)
            booking_amounts[booking_id] = amount_minor
            total_amount += amount_minor

        if total_amount <= 0:
            raise StripeServiceError("Amount must be greater than 0.")

        metadata = {
            "booking_ids": ",".join(booking_ids),
            "booking_amounts": json.dumps(booking_amounts),
        }

        try:
            return stripe.PaymentIntent.create(
                amount=total_amount,
                currency=currency,
                automatic_payment_methods={"enabled": True},
                metadata=metadata,
            )
        except stripe.error.StripeError as exc:
            raise StripeServiceError(str(exc)) from exc

    def retrieve_payment_intent(self, payment_intent_id: str) -> dict:
        if not payment_intent_id:
            raise StripeServiceError("payment_intent_id is required.")
        try:
            intent = stripe.PaymentIntent.retrieve(payment_intent_id)
            return intent.to_dict() if hasattr(intent, "to_dict") else dict(intent)
        except stripe.error.StripeError as exc:
            raise StripeServiceError(str(exc)) from exc
