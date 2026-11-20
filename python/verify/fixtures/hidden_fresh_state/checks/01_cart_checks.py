from review_koans.checks import twin


def adds_one(review):
    assert review.add("PEAR-7") == ["PEAR-7"]


CASES = [twin("adding an item", adds_one), twin("adding an item again", adds_one)]
