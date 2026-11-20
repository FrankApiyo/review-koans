from review_koans.checks import exploit, twin


class Outbox:
    def __init__(self):
        self.pushed = []

    def push(self, i):
        self.pushed.append(i)
        if i % 2:
            raise ConnectionError(i)


def all_succeed(review):
    outbox = Outbox()
    assert review.sync([2, 4], outbox.push) == []
    assert review.sync([], outbox.push) == []
    assert outbox.pushed == [2, 4]


def some_fail(review):
    outbox = Outbox()
    assert review.sync([1, 2, 3, 4], outbox.push) == [1, 3]
    assert outbox.pushed == [1, 2, 3, 4]


CASES = [
    twin("pushes that all succeed", all_succeed),
    exploit("a run where some pushes fail", some_fail),
]
