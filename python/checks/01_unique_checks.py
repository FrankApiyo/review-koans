from review_koans.checks import exploit, twin


def repeated_calls(review):
    assert review.unique(["a", "b", "a"]) == ["a", "b"]
    assert review.unique(["a"]) == ["a"]


def shared_seen(review):
    seen = set()
    assert review.unique(["a"], seen) == ["a"]
    assert review.unique(["a", "b"], seen) == ["b"]
    assert seen == {"a", "b"}


CASES = [
    twin("repeated calls without a set", repeated_calls),
    exploit("one set shared across batches", shared_seen),
]
