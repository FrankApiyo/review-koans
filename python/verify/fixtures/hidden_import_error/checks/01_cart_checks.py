from review_koans.checks import twin


def adds_an_item(review):
    assert review.add({}, "PEAR-7", 2) == {"PEAR-7": 2}


CASES = [twin("adding an item", adds_an_item)]
