from review_koans.checks import twin


def accepts_a_sku(review):
    assert review.is_sku("PEAR-7")


CASES = [twin("a real sku", accepts_a_sku)]
