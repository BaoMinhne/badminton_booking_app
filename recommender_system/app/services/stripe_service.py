import os

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
        amount_minor: int,
        currency: str,
        booking_ids: list[str],
    ) -> stripe.PaymentIntent:
        if amount_minor <= 0:
            raise StripeServiceError("Amount must be greater than 0.")
        if not currency:
            raise StripeServiceError("Currency is required.")
        if not booking_ids:
            raise StripeServiceError("booking_ids must not be empty.")

        metadata = {"booking_ids": ",".join(booking_ids)}

        try:
            return stripe.PaymentIntent.create(
                amount=amount_minor,
                currency=currency,
                automatic_payment_methods={"enabled": True},
                metadata=metadata,
            )
        except stripe.error.StripeError as exc:
            raise StripeServiceError(str(exc)) from exc
