from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field

from app.services.stripe_service import StripeService, StripeServiceError

router = APIRouter(prefix="/payments", tags=["payments"])


class PaymentIntentRequest(BaseModel):
    amount_minor: int = Field(..., ge=1)
    currency: str = Field(..., min_length=1)
    booking_ids: list[str] = Field(..., min_length=1)


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
            amount_minor=payload.amount_minor,
            currency=payload.currency,
            booking_ids=payload.booking_ids,
        )
        if not intent.client_secret:
            raise StripeServiceError("Missing client secret from Stripe.")
        return PaymentIntentResponse(
            client_secret=intent.client_secret,
            payment_intent_id=intent.id,
        )
    except StripeServiceError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=exc.message,
        ) from exc
