from review_koans.checks import exploit, twin


def record_with_email(review):
    assert review.collect_errors({"id": 1, "email": "ada@example.com"}) == []


def caller_list(review):
    errors = []
    review.collect_errors({"id": 1}, errors)
    review.collect_errors({"id": 2, "email": "ada@example.com"}, errors)
    returned = review.collect_errors({"id": 3}, errors)
    assert errors == ["1: missing email", "3: missing email"]
    assert returned is errors


def two_calls(review):
    assert review.collect_errors({"id": 1}) == ["1: missing email"]
    assert review.collect_errors({"id": 2}) == ["2: missing email"]


CASES = [
    twin("a record with an email", record_with_email),
    twin("a caller's list gathering several records", caller_list),
    exploit("two calls in a row without a list", two_calls),
]
