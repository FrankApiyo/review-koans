"""Daily sales summary. summarize counts the rows marked ok and totals their amounts."""

from collections.abc import Iterable


def summarize(rows: Iterable[dict]) -> dict[str, int]:
    valid = (r for r in rows if r["ok"])
    count = sum(1 for _ in valid)
    total = sum(r["amount"] for r in valid)
    return {"count": count, "total": total}
