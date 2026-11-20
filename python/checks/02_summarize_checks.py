from review_koans.checks import exploit, twin

ROWS = [{"ok": True, "amount": 5}, {"ok": False, "amount": 7}, {"ok": True, "amount": 3}]


def reader():
    yield from (dict(row) for row in ROWS)


def no_rows(review):
    assert review.summarize([]) == {"count": 0, "total": 0}


def count(review):
    assert review.summarize(list(ROWS))["count"] == 2


def total(review):
    assert review.summarize(list(ROWS)) == {"count": 2, "total": 8}


def streamed(review):
    assert review.summarize(reader()) == {"count": 2, "total": 8}


CASES = [
    twin("no rows", no_rows),
    twin("the count of the rows marked ok", count),
    exploit("the total of the rows marked ok", total),
    exploit("rows streamed from a reader", streamed),
]
