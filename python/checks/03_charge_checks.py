from review_koans.checks import exploit, twin

ORDER = {"id": "o-1", "amount": 1250}


class Gateway:
    def __init__(self, error=None):
        self.error = error

    def charge(self, order_id, amount):
        if self.error is not None:
            raise self.error
        return f"receipt {order_id} {amount}"


def charged(review):
    assert review.charge(Gateway(), ORDER) == "receipt o-1 1250"


def raised_by(review, error):
    try:
        review.charge(Gateway(error), ORDER)
    except review.ChargeError as failure:
        return failure
    raise AssertionError


def declined(review):
    raised_by(review, review.GatewayError("card declined"))


def reason(review):
    error = review.GatewayError("card declined")
    assert raised_by(review, error).__cause__ is error


def names_the_order(review):
    assert raised_by(review, review.GatewayError("card declined")).args == ("o-1",)


CASES = [
    twin("a charge the gateway accepts", charged),
    twin("a charge the gateway declines", declined),
    exploit("the reason a charge was declined", reason),
    exploit("the order a declined charge names", names_the_order),
]
