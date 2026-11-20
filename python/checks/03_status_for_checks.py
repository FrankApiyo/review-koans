from review_koans.checks import exploit, twin


class BadQuantity(ValueError):
    pass


def failing(error):
    def op():
        raise error

    return op


def success(review):
    assert review.status_for(lambda: None) == 200


def other_failure(review):
    assert review.status_for(failing(RuntimeError("down"))) == 500
    assert review.status_for(failing(KeyError("id"))) == 500


def bad_input(review):
    assert review.status_for(failing(ValueError("qty"))) == 400
    assert review.status_for(failing(BadQuantity("qty"))) == 400


def not_found(review):
    assert review.status_for(failing(review.NotFound("o-1"))) == 404


CASES = [
    twin("an operation that succeeds", success),
    twin("an operation that fails some other way", other_failure),
    exploit("an operation given bad input", bad_input),
    exploit("an operation that finds nothing", not_found),
]
