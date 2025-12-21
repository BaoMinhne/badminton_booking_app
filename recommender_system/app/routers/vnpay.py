import hashlib
import hmac
import os
import urllib.parse
from datetime import datetime, timezone, timedelta
from typing import Any, Dict, Optional

from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel, Field

from pocketbase_client import create_record, get_list, update_record

router = APIRouter(prefix="/vnpay", tags=["vnpay"])


class CreatePaymentRequest(BaseModel):
    booking_id: str = Field(..., alias="bookingId")
    amount_minor: int = Field(..., alias="amountMinor", ge=1)
    currency: str = Field(..., alias="currency")
    description: str = Field(..., alias="description")
    return_url: Optional[str] = Field(None, alias="returnUrl")


class CreatePaymentResponse(BaseModel):
    payment_url: str = Field(..., alias="paymentUrl")
    payment_id: Optional[str] = Field(None, alias="paymentId")
    transaction_ref: str = Field(..., alias="transactionRef")


def _get_env(name: str) -> str:
    value = os.getenv(name)
    if not value:
        raise HTTPException(
            status_code=500, detail=f"Missing required env: {name}"
        )
    return value


def _vnpay_timestamp() -> str:
    now = datetime.now(timezone(timedelta(hours=7)))
    return now.strftime("%Y%m%d%H%M%S")


def _sign_params(params: Dict[str, Any], secret: str) -> str:
    ordered = sorted((k, str(v)) for k, v in params.items() if v is not None)
    query = urllib.parse.urlencode(ordered, doseq=True)
    signature = hmac.new(
        secret.encode("utf-8"),
        query.encode("utf-8"),
        hashlib.sha512,
    ).hexdigest()
    return signature


def _build_payment_url(params: Dict[str, Any], base_url: str, secret: str) -> str:
    signature = _sign_params(params, secret)
    params_with_hash = {**params, "vnp_SecureHash": signature}
    query = urllib.parse.urlencode(sorted(params_with_hash.items()))
    return f"{base_url}?{query}"


@router.post("/create-payment", response_model=CreatePaymentResponse)
async def create_payment(payload: CreatePaymentRequest, request: Request):
    vnp_tmn_code = _get_env("VNPAY_TMN_CODE")
    vnp_hash_secret = _get_env("VNPAY_HASH_SECRET")
    vnp_base_url = _get_env("VNPAY_BASE_URL")
    vnp_return_url = payload.return_url or _get_env("VNPAY_RETURN_URL")

    amount_minor = payload.amount_minor
    vnp_amount = amount_minor * 100
    transaction_ref = f"{payload.booking_id}-{int(datetime.now().timestamp())}"

    vnp_params: Dict[str, Any] = {
        "vnp_Version": "2.1.0",
        "vnp_Command": "pay",
        "vnp_TmnCode": vnp_tmn_code,
        "vnp_Amount": vnp_amount,
        "vnp_CurrCode": payload.currency,
        "vnp_TxnRef": transaction_ref,
        "vnp_OrderInfo": payload.description,
        "vnp_OrderType": "other",
        "vnp_Locale": "vn",
        "vnp_ReturnUrl": vnp_return_url,
        "vnp_IpAddr": request.client.host if request.client else "127.0.0.1",
        "vnp_CreateDate": _vnpay_timestamp(),
    }

    payment_record = await create_record(
        "payment",
        {
            "booking_id": payload.booking_id,
            "amount_minor": amount_minor,
            "currency": payload.currency,
            "provider": "vnpay",
            "status": "pending",
            "transaction_ref": transaction_ref,
            "payload": payload.model_dump_json(by_alias=True),
        },
    )

    payment_url = _build_payment_url(vnp_params, vnp_base_url, vnp_hash_secret)

    return CreatePaymentResponse(
        paymentUrl=payment_url,
        paymentId=payment_record.get("id"),
        transactionRef=transaction_ref,
    )


def _extract_vnpay_params(query: Dict[str, str]) -> Dict[str, str]:
    return {k: v for k, v in query.items() if k.startswith("vnp_")}


def _verify_signature(params: Dict[str, str], secret: str) -> bool:
    secure_hash = params.pop("vnp_SecureHash", None)
    params.pop("vnp_SecureHashType", None)
    if not secure_hash:
        return False
    signature = _sign_params(params, secret)
    return signature == secure_hash


@router.get("/ipn")
async def vnpay_ipn(request: Request):
    params = _extract_vnpay_params(dict(request.query_params))
    vnp_hash_secret = _get_env("VNPAY_HASH_SECRET")

    if not _verify_signature(params.copy(), vnp_hash_secret):
        return {"RspCode": "97", "Message": "Invalid signature"}

    txn_ref = params.get("vnp_TxnRef")
    response_code = params.get("vnp_ResponseCode")
    transaction_status = params.get("vnp_TransactionStatus")

    if not txn_ref:
        return {"RspCode": "01", "Message": "Missing transaction ref"}

    status = "pending"
    if response_code == "00" and transaction_status == "00":
        status = "succeeded"
    elif response_code and response_code != "00":
        status = "failed"
    elif transaction_status and transaction_status != "00":
        status = "failed"

    result = await get_list(
        "payment",
        page=1,
        per_page=1,
        filter_expr=f'transaction_ref = "{txn_ref}"',
        sort="-created",
    )
    items = result.get("items", [])
    if not items:
        return {"RspCode": "01", "Message": "Payment not found"}

    payment = items[0]
    await update_record(
        "payment",
        payment["id"],
        {
            "status": status,
            "payload": urllib.parse.urlencode(params),
        },
    )

    return {"RspCode": "00", "Message": "Confirm Success"}


@router.get("/return")
async def vnpay_return(request: Request):
    params = _extract_vnpay_params(dict(request.query_params))
    vnp_hash_secret = _get_env("VNPAY_HASH_SECRET")
    if not _verify_signature(params.copy(), vnp_hash_secret):
        raise HTTPException(status_code=400, detail="Invalid signature")
    return {
        "responseCode": params.get("vnp_ResponseCode"),
        "transactionStatus": params.get("vnp_TransactionStatus"),
        "transactionRef": params.get("vnp_TxnRef"),
    }
