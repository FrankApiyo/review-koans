from review_koans.checks import exploit, twin


def empty(review):
    assert review.prune({}) == {}


def nothing_to_prune(review):
    assert review.prune({"a": 1, "b": 0}) == {"a": 1, "b": 0}


def several_unset(review):
    assert review.prune({"a": None, "b": 1, "c": None}) == {"b": 1}


def callers_dict(review):
    settings = {"a": None, "b": 1}
    returned = review.prune(settings)
    assert settings == {"b": 1}
    assert returned is settings


CASES = [
    twin("no settings", empty),
    twin("settings that all have values", nothing_to_prune),
    exploit("several settings without a value", several_unset),
    exploit("the caller's own settings afterwards", callers_dict),
]
