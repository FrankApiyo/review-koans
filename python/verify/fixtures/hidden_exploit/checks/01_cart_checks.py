from review_koans.checks import exploit, twin


def adds_an_item(review):
    assert review.add({}, "PEAR-7", 2) == {"PEAR-7": 2}


def empty_add(review):
    assert review.add({}, "ZX-99", 0) == {}


CASES = [twin("adding an item", adds_an_item), exploit("an empty add", empty_add)]
