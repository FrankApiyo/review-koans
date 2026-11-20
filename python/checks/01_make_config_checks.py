from review_koans.checks import exploit, twin

PLAIN = {"timeout": 5, "headers": {"Accept": "application/json"}}


def no_token(review):
    assert review.make_config() == PLAIN


def with_token(review):
    config = review.make_config("t")
    assert config == {"timeout": 5, "headers": {"Accept": "application/json", "Authorization": "Bearer t"}}


def after_a_token(review):
    review.make_config("secret")
    assert review.make_config() == PLAIN
    assert review.DEFAULTS == PLAIN


def two_tokens(review):
    first = review.make_config("alice")
    second = review.make_config("bob")
    assert first["headers"]["Authorization"] == "Bearer alice"
    assert second["headers"]["Authorization"] == "Bearer bob"


CASES = [
    twin("a config with no token", no_token),
    twin("a config with a token", with_token),
    exploit("a config made after one with a token", after_a_token),
    exploit("two configs with different tokens", two_tokens),
]
