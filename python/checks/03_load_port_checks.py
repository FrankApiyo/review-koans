from review_koans.checks import exploit, raises, twin


def no_port(review):
    assert review.load_port({}) == 8080
    assert review.load_port({"host": "0.0.0.0"}) == 8080


def numeric_port(review):
    assert review.load_port({"port": "9000"}) == 9000
    assert review.load_port({"port": 9000}) == 9000


def not_a_number(review):
    for port in ("80a", "", "8.5"):
        with raises(ValueError):
            review.load_port({"port": port})


CASES = [
    twin("a config without a port", no_port),
    twin("a config with a numeric port", numeric_port),
    exploit("a port that is not a whole number", not_a_number),
]
