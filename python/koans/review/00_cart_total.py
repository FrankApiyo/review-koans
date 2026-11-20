"""Each line of a cart holds a quantity and a unit price in cents."""


def total(lines: list[dict[str, int]]) -> int:
    return sum(
        line["qty"] * line["unit_cents"]
        for line in lines
    )
