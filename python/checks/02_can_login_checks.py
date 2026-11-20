import json

from review_koans.checks import exploit, twin


def parsed(text):
    return json.loads(json.dumps(text))


def active(review):
    assert review.can_login(parsed("active")) is True


def suspended(review):
    assert review.can_login(parsed("suspended")) is False


def not_active(review):
    assert review.can_login(parsed("act")) is False
    assert review.can_login(parsed("")) is False
    assert review.can_login(parsed("active_pending")) is False
    assert review.can_login(parsed("inactive")) is False


CASES = [
    twin("an active status parsed at run time", active),
    twin("a suspended status", suspended),
    exploit("a status that is not active", not_active),
]
