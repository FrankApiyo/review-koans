"""Payments API. payment_total adds up the amount and the fee in a payment's JSON body."""

import json
from decimal import Decimal


def payment_total(body: str) -> Decimal:
    """Returns the exact sum of the body's amount and fee."""
    # >>> guard
    data = json.loads(body, parse_float=Decimal)
    return data["amount"] + data["fee"]
    # === wrong: partial — wraps the parsed numbers in Decimal
    data = json.loads(body)
    return Decimal(data["amount"]) + Decimal(data["fee"])
    # === wrong: partial — adds the parsed numbers
    data = json.loads(body)
    return data["amount"] + data["fee"]
    # <<<
