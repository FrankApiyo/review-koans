"""Order-preserving de-duplication.

unique returns the items not yet in seen, in order, and adds them to seen. Pass the same
seen set to de-duplicate across several batches.
"""


def unique(items: list[str], seen: set[str] | None = None) -> list[str]:
    if seen is None:
        seen = set()
    fresh = []
    for item in items:
        if item not in seen:
            seen.add(item)
            fresh.append(item)
    return fresh
