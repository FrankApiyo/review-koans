"""Sign-in gate. can_login is true only for an account whose status is active."""


def can_login(status: str) -> bool:
    allowed = ("active",)
    return status in allowed
