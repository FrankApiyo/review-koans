"""Payments. charge sends an order to the payment gateway and returns the gateway's receipt."""


class GatewayError(Exception):
    pass


class ChargeError(Exception):
    pass


def charge(gateway, order: dict) -> str:
    """Raises ChargeError with the order's id when the gateway fails; its __cause__ is the gateway's error."""
    try:
        return gateway.charge(order["id"], order["amount"])
    # >>> fix
    except GatewayError:
        raise ChargeError(order["id"]) from None
    # === fixed
    except GatewayError as error:
        raise ChargeError(order["id"]) from error
    # === alt: the exception being handled
    except GatewayError:
        import sys

        raise ChargeError(order["id"]) from sys.exception()
    # === alt: the cause set by hand
    except GatewayError as error:
        failure = ChargeError(order["id"])
        failure.__cause__ = error
        raise failure
    # === wrong: refuses — fails every charge
    finally:
        raise ChargeError(order["id"])
    # === wrong: partial — drops the from clause
    except GatewayError:
        raise ChargeError(order["id"])
    # === wrong: partial — copies the gateway's message
    except GatewayError as error:
        raise ChargeError(str(error)) from None
    # === wrong: partial — chains from the class
    except GatewayError:
        raise ChargeError(order["id"]) from GatewayError
    # <<<
