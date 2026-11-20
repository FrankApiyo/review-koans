"""Each line of a cart holds a quantity and a unit price in cents."""


def total(lines: list[dict[str, int]]) -> int:
    return sum(
        # >>> guard
        line["qty"] * line["unit_cents"]
        # === wrong: partial — drops the qty factor
        line["unit_cents"]
        # <<<
        for line in lines
    )
