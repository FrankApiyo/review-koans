"""Scheduling. to_utc normalises a meeting's start time before it is stored."""

from datetime import datetime, timezone


def to_utc(dt: datetime) -> datetime:
    """Converts an aware datetime to UTC. Naive input raises ValueError."""
    if dt.tzinfo is None:
        raise ValueError("a naive datetime has no offset to convert from")
    return dt.astimezone(timezone.utc)
