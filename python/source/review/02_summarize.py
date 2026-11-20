"""Daily sales summary. summarize counts the rows marked ok and totals their amounts."""

from collections.abc import Iterable


def summarize(rows: Iterable[dict]) -> dict[str, int]:
    # >>> fix
    valid = (r for r in rows if r["ok"])
    count = sum(1 for _ in valid)
    total = sum(r["amount"] for r in valid)
    # === fixed
    valid = [r for r in rows if r["ok"]]
    count = sum(1 for _ in valid)
    total = sum(r["amount"] for r in valid)
    # === alt: itertools.tee
    from itertools import tee

    valid, again = tee(r for r in rows if r["ok"])
    count = sum(1 for _ in valid)
    total = sum(r["amount"] for r in again)
    # === wrong: refuses — counts no rows
    count = 0
    total = 0
    # === wrong: partial — filter
    valid = filter(lambda r: r["ok"], rows)
    count = sum(1 for _ in valid)
    total = sum(r["amount"] for r in valid)
    # === wrong: partial — copies the rows first
    rows = list(rows)
    valid = (r for r in rows if r["ok"])
    count = sum(1 for _ in valid)
    total = sum(r["amount"] for r in valid)
    # === wrong: partial — reads the rows again for the total
    valid = (r for r in rows if r["ok"])
    count = sum(1 for _ in valid)
    total = sum(r["amount"] for r in rows if r["ok"])
    # <<<
    return {"count": count, "total": total}
