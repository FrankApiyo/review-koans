"""Payments. charge sends an order to the payment gateway and returns the gateway's receipt."""


class GatewayError(Exception):
    pass


class ChargeError(Exception):
    pass


def charge(gateway, order: dict) -> str:
    """Raises ChargeError with the order's id when the gateway fails; its __cause__ is the gateway's error."""
    try:
        return gateway.charge(order["id"], order["amount"])
    except GatewayError as error:
        raise ChargeError(order["id"]) from error
