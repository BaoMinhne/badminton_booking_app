import argparse
import asyncio
import os
from typing import Any, Dict, Optional, Tuple

import httpx

from pocketbase_client import client as pb_client
from pocketbase_client import get_list, update_record


DEFAULT_PROVIDER = "nominatim"
DEFAULT_ADDRESS_FIELD = "location"
DEFAULT_LAT_FIELD = "latitude"
DEFAULT_LNG_FIELD = "longitud3"


class GeocodeError(RuntimeError):
    pass


def _env_or_default(key: str, fallback: str) -> str:
    value = os.getenv(key)
    return value.strip() if value else fallback


async def _geocode_nominatim(
    client: httpx.AsyncClient,
    address: str,
    *,
    user_agent: str,
) -> Optional[Tuple[float, float]]:
    response = await client.get(
        "https://nominatim.openstreetmap.org/search",
        params={
            "q": address,
            "format": "json",
            "limit": 1,
        },
        headers={"User-Agent": user_agent},
    )
    response.raise_for_status()
    results = response.json()
    if not results:
        return None
    result = results[0]
    return float(result["lat"]), float(result["lon"])


async def _geocode_google(
    client: httpx.AsyncClient,
    address: str,
    *,
    api_key: str,
) -> Optional[Tuple[float, float]]:
    response = await client.get(
        "https://maps.googleapis.com/maps/api/geocode/json",
        params={"address": address, "key": api_key},
    )
    response.raise_for_status()
    payload = response.json()
    if payload.get("status") != "OK":
        return None
    result = payload["results"][0]["geometry"]["location"]
    return float(result["lat"]), float(result["lng"])


async def _geocode_mapbox(
    client: httpx.AsyncClient,
    address: str,
    *,
    api_key: str,
) -> Optional[Tuple[float, float]]:
    response = await client.get(
        f"https://api.mapbox.com/geocoding/v5/mapbox.places/{address}.json",
        params={"access_token": api_key, "limit": 1},
    )
    response.raise_for_status()
    payload = response.json()
    features = payload.get("features", [])
    if not features:
        return None
    lng, lat = features[0]["center"]
    return float(lat), float(lng)


async def geocode_address(
    client: httpx.AsyncClient,
    provider: str,
    address: str,
    *,
    user_agent: str,
    api_key: Optional[str],
) -> Optional[Tuple[float, float]]:
    if provider == "nominatim":
        return await _geocode_nominatim(client, address, user_agent=user_agent)
    if provider == "google":
        if not api_key:
            raise GeocodeError("Missing GOOGLE_MAPS_API_KEY for Google Geocoding.")
        return await _geocode_google(client, address, api_key=api_key)
    if provider == "mapbox":
        if not api_key:
            raise GeocodeError("Missing MAPBOX_TOKEN for Mapbox Geocoding.")
        return await _geocode_mapbox(client, address, api_key=api_key)
    raise GeocodeError(f"Unsupported provider: {provider}")


def _is_missing(value: Any, *, zero_is_missing: bool) -> bool:
    if value is None:
        return True
    if isinstance(value, str) and not value.strip():
        return True
    if zero_is_missing and isinstance(value, (int, float)) and value == 0:
        return True
    return False


async def run_geocoding(args: argparse.Namespace) -> None:
    geocode_client = httpx.AsyncClient(timeout=20.0)
    processed = 0
    updated = 0
    skipped = 0
    page = 1

    try:
        while True:
            data = await get_list("courts", page=page, per_page=args.per_page)
            items = data.get("items", [])
            if not items:
                break

            for item in items:
                if args.max_records and processed >= args.max_records:
                    return

                processed += 1
                address = item.get(args.address_field)
                if _is_missing(address, zero_is_missing=False):
                    skipped += 1
                    print(f"[SKIP] {item.get('id')} missing address field.")
                    continue

                lat_value = item.get(args.lat_field)
                lng_value = item.get(args.lng_field)
                if (
                    not _is_missing(lat_value, zero_is_missing=args.zero_is_missing)
                    and not _is_missing(lng_value, zero_is_missing=args.zero_is_missing)
                ):
                    skipped += 1
                    print(f"[SKIP] {item.get('id')} already has coordinates.")
                    continue

                coords = await geocode_address(
                    geocode_client,
                    args.provider,
                    str(address),
                    user_agent=args.user_agent,
                    api_key=args.api_key,
                )
                if coords is None:
                    skipped += 1
                    print(f"[MISS] {item.get('id')} no geocode match.")
                    await asyncio.sleep(args.rate_limit)
                    continue

                lat, lng = coords
                if args.dry_run:
                    print(
                        "[DRY-RUN]",
                        item.get("id"),
                        f"{args.lat_field}={lat}",
                        f"{args.lng_field}={lng}",
                    )
                else:
                    await update_record(
                        "courts",
                        item["id"],
                        {args.lat_field: lat, args.lng_field: lng},
                    )
                    updated += 1
                    print(f"[UPDATE] {item.get('id')} -> {lat}, {lng}")

                await asyncio.sleep(args.rate_limit)

            page += 1
    finally:
        await geocode_client.aclose()
        await pb_client.aclose()

    print(
        "Done.",
        f"processed={processed}",
        f"updated={updated}",
        f"skipped={skipped}",
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Geocode court addresses and store latitude/longitude in PocketBase.",
    )
    parser.add_argument(
        "--provider",
        choices=["nominatim", "google", "mapbox"],
        default=_env_or_default("GEOCODE_PROVIDER", DEFAULT_PROVIDER),
        help="Geocoding provider to use.",
    )
    parser.add_argument(
        "--address-field",
        default=_env_or_default("GEOCODE_ADDRESS_FIELD", DEFAULT_ADDRESS_FIELD),
        help="Field name containing the address text.",
    )
    parser.add_argument(
        "--lat-field",
        default=_env_or_default("GEOCODE_LAT_FIELD", DEFAULT_LAT_FIELD),
        help="Field name for latitude in PocketBase.",
    )
    parser.add_argument(
        "--lng-field",
        default=_env_or_default("GEOCODE_LNG_FIELD", DEFAULT_LNG_FIELD),
        help="Field name for longitude in PocketBase.",
    )
    parser.add_argument(
        "--rate-limit",
        type=float,
        default=float(os.getenv("GEOCODE_RATE_LIMIT", "1.0")),
        help="Delay in seconds between geocoding requests.",
    )
    parser.add_argument(
        "--per-page",
        type=int,
        default=50,
        help="Number of courts to fetch per page from PocketBase.",
    )
    parser.add_argument(
        "--max-records",
        type=int,
        default=0,
        help="Maximum number of courts to process (0 for no limit).",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print updates without writing to PocketBase.",
    )
    parser.add_argument(
        "--zero-is-missing",
        action=argparse.BooleanOptionalAction,
        default=os.getenv("GEOCODE_ZERO_IS_MISSING", "true").lower() != "false",
        help="Treat 0 values as missing coordinates (default: true).",
    )
    return parser


def _resolve_api_key(provider: str) -> Optional[str]:
    if provider == "google":
        return os.getenv("GOOGLE_MAPS_API_KEY")
    if provider == "mapbox":
        return os.getenv("MAPBOX_TOKEN")
    return None


async def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    args.api_key = _resolve_api_key(args.provider)
    args.user_agent = _env_or_default(
        "NOMINATIM_USER_AGENT",
        "badminton-booking-app-geocoder/1.0",
    )
    if args.provider in {"google", "mapbox"} and not args.api_key:
        raise GeocodeError("Missing API key for selected provider.")
    await run_geocoding(args)


if __name__ == "__main__":
    asyncio.run(main())
