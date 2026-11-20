from review_koans.checks import exploit, twin


def two_sizes(review):
    assert len(review.unique_skus([review.Sku("tee", "M"), review.Sku("tee", "L")])) == 2


def listed_twice(review):
    assert len(review.unique_skus([review.Sku("tee", "M"), review.Sku("tee", "M")])) == 1


def changed_after_storing(review):
    sku = review.Sku("tee", "M")
    stored = review.unique_skus([sku])
    try:
        sku.size = "L"
    except AttributeError:
        return
    assert sku in stored


CASES = [
    twin("two sizes of one product", two_sizes),
    exploit("a SKU listed twice", listed_twice),
    exploit("a SKU changed after it was stored", changed_after_storing),
]
