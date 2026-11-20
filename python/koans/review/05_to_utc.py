"""Scheduling. to_utc normalises a meeting's start time before it is stored."""

from datetime import datetime, timezone


def to_utc(dt: datetime) -> datetime:
    """Converts an aware datetime to UTC. Naive input raises ValueError."""
    return dt.replace(tzinfo=timezone.utc)
