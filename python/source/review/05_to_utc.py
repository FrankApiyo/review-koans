"""Scheduling. to_utc normalises a meeting's start time before it is stored."""

from datetime import datetime, timezone


def to_utc(dt: datetime) -> datetime:
    """Converts an aware datetime to UTC. Naive input raises ValueError."""
    # >>> fix
    return dt.replace(tzinfo=timezone.utc)
    # === fixed
    if dt.tzinfo is None:
        raise ValueError("a naive datetime has no offset to convert from")
    return dt.astimezone(timezone.utc)
    # === alt: checks the offset
    if dt.utcoffset() is None:
        raise ValueError("a naive datetime has no offset to convert from")
    return dt.astimezone(timezone.utc)
    # === wrong: refuses — accepts no time
    raise ValueError(dt)
    # === wrong: partial — converts without checking
    return dt.astimezone(timezone.utc)
    # === wrong: partial — checks, then relabels
    if dt.tzinfo is None:
        raise ValueError("a naive datetime has no offset to convert from")
    return dt.replace(tzinfo=timezone.utc)
    # <<<
