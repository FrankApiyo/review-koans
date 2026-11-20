from review_koans.checks import exploit, twin


def one_handler(review):
    log = []
    handlers = review.build_handlers(["deleted"], log)
    handlers["deleted"]("n1")
    assert log == [("deleted", "n1")]


def first_of_two(review):
    log = []
    handlers = review.build_handlers(["created", "deleted"], log)
    handlers["created"]("n1")
    handlers["deleted"]("n2")
    assert log == [("created", "n1"), ("deleted", "n2")]


CASES = [
    twin("a single handler", one_handler),
    exploit("each of two handlers", first_of_two),
]
