from review_koans.checks import exploit


def notifies(review):
    told = []

    async def record(sku):
        told.append(sku)

    review._notify = record
    review.add([], "PEAR-7")
    assert told == ["PEAR-7"]


CASES = [exploit("the warehouse is never told", notifies)]
