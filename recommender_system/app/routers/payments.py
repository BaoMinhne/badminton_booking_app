import json
import os

import stripe
from fastapi import APIRouter, HTTPException, Request, status
from pydantic import BaseModel, Field

from app.services.stripe_service import StripeService, StripeServiceError
from pocketbase_client import create_record, get_list, update_record

router = APIRouter(prefix="/payments", tags=["payments"])


class BookingPaymentRequest(BaseModel):
    booking_id: str = Field(..., min_length=1)
    amount_minor: int = Field(..., ge=1)


class PaymentIntentRequest(BaseModel):
    currency: str = Field(..., min_length=1)
    bookings: list[BookingPaymentRequest] = Field(..., min_length=1)


class PaymentIntentResponse(BaseModel):
    client_secret: str
    payment_intent_id: str


@router.post(
    "/intent",
    response_model=PaymentIntentResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_payment_intent(payload: PaymentIntentRequest) -> PaymentIntentResponse:
    try:
        service = StripeService()
        intent = service.create_payment_intent(
            currency=payload.currency,
            bookings=[booking.model_dump() for booking in payload.bookings],
        )
        if not intent.client_secret:
            raise StripeServiceError("Missing client secret from Stripe.")
        await _record_pending_payments(
            payload.bookings,
            currency=payload.currency,
            payment_intent_id=intent.id,
        )
        return PaymentIntentResponse(
            client_secret=intent.client_secret,
            payment_intent_id=intent.id,
        )
    except StripeServiceError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=exc.message,
        ) from exc


@router.post("/webhook")
async def stripe_webhook(request: Request) -> dict:
    payload = await request.body()
    signature = request.headers.get("stripe-signature")
    webhook_secret = os.getenv("STRIPE_WEBHOOK_SECRET")
    if not webhook_secret:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Missing STRIPE_WEBHOOK_SECRET.",
        )
    if not signature:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Missing stripe-signature header.",
        )

    try:
        event = stripe.Webhook.construct_event(
            payload=payload,
            sig_header=signature,
            secret=webhook_secret,
        )
    except stripe.error.SignatureVerificationError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid Stripe signature.",
        ) from exc

    if event["type"] == "payment_intent.succeeded":
        intent = event["data"]["object"]
        await _handle_intent_update(intent, status="succeeded")
    elif event["type"] == "payment_intent.payment_failed":
        intent = event["data"]["object"]
        await _handle_intent_update(intent, status="failed")

    return {"received": True}


async def _record_pending_payments(
    bookings: list[BookingPaymentRequest],
    *,
    currency: str,
    payment_intent_id: str,
) -> None:
    for booking in bookings:
        await create_record(
            "payment",
            {
                "booking_id": booking.booking_id,
                "amount_minor": booking.amount_minor,
                "currency": currency.upper(),
                "provider": "stripe",
                "status": "pending",
                "transaction_ref": payment_intent_id,
            },
        )


async def _handle_intent_update(intent: dict, *, status: str) -> None:
    metadata = intent.get("metadata") or {}
    booking_ids_raw = metadata.get("booking_ids") or ""
    booking_ids = [item for item in booking_ids_raw.split(",") if item]
    booking_amounts_raw = metadata.get("booking_amounts") or "{}"
    try:
        booking_amounts = json.loads(booking_amounts_raw)
    except json.JSONDecodeError:
        booking_amounts = {}

    for booking_id in booking_ids:
        await _upsert_payment_record(
            booking_id,
            status=status,
            payment_intent_id=intent.get("id"),
            amount_minor=booking_amounts.get(booking_id),
            currency=intent.get("currency"),
        )
        if status == "succeeded":
            await update_record(
                "court_bookings",
                booking_id,
                {"status": "confirmed"},
            )


async def _upsert_payment_record(
    booking_id: str,
    *,
    status: str,
    payment_intent_id: str | None,
    amount_minor: int | None,
    currency: str | None,
) -> None:
    result = await get_list(
        "payment",
        page=1,
        per_page=1,
        filter_expr=f'booking_id="{booking_id}"',
    )
    items = result.get("items", [])
    data = {
        "status": status,
        "provider": "stripe",
    }
    if payment_intent_id:
        data["transaction_ref"] = payment_intent_id
    if amount_minor:
        data["amount_minor"] = amount_minor
    if currency:
        data["currency"] = currency.upper()

    if items:
        await update_record("payment", items[0]["id"], data)
    else:
        data["booking_id"] = booking_id
        await create_record("payment", data)
