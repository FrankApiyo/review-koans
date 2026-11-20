from review_koans.checks import exploit, twin


def one_cart(review):
    cart = review.Cart()
    cart.add("x")
    cart.add("y")
    assert cart.items == ["x", "y"]


def two_carts(review):
    first, second = review.Cart(), review.Cart()
    first.add("x")
    assert first.items == ["x"]
    assert second.items == []


CASES = [
    twin("one cart with two items", one_cart),
    exploit("two carts", two_carts),
]
