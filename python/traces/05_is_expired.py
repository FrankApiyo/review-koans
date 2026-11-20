from datetime import datetime, timezone


def is_expired(expires_at, now):
    return now >= expires_at


expires_at = datetime.fromisoformat("2026-03-01T12:00:00+00:00")
now = datetime(2026, 3, 1, 13, 0)
print(is_expired(expires_at, now))
