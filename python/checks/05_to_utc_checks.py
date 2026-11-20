from datetime import datetime, timedelta, timezone

from review_koans.checks import exploit, raises, twin


def converted(review, start):
    result = review.to_utc(start)
    assert result.utcoffset() == timedelta(0)
    return result.replace(tzinfo=None)


def in_utc(review):
    assert converted(review, datetime(2026, 3, 1, 12, 0, tzinfo=timezone.utc)) == datetime(2026, 3, 1, 12, 0)


def other_offset(review):
    east = datetime(2026, 3, 1, 15, 0, tzinfo=timezone(timedelta(hours=3)))
    west = datetime(2026, 3, 1, 7, 30, tzinfo=timezone(timedelta(hours=-5)))
    assert converted(review, east) == datetime(2026, 3, 1, 12, 0)
    assert converted(review, west) == datetime(2026, 3, 1, 12, 30)


def naive(review):
    with raises(ValueError):
        review.to_utc(datetime(2026, 3, 1, 12, 0))


CASES = [
    twin("a time already in UTC", in_utc),
    exploit("a time at another offset", other_offset),
    exploit("a time with no offset", naive),
]
