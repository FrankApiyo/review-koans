"""Payments API. payment_total adds up the amount and the fee in a payment's JSON body."""

import json
from decimal import Decimal


def payment_total(body: str) -> Decimal:
    """Returns the exact sum of the body's amount and fee."""
    data = json.loads(body, parse_float=Decimal)
    return data["amount"] + data["fee"]
