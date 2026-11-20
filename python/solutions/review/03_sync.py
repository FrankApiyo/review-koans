"""Outbox sync. sync pushes each id and returns the ids whose push failed, in order."""


def sync(ids: list[int], push) -> list[int]:
    failed = []
    for i in ids:
        try:
            push(i)
        except Exception:
            failed.append(i)
    return failed
