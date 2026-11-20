"""Sign-in gate. can_login is true only for an account whose status is active."""


def can_login(status: str) -> bool:
    # >>> fix
    allowed = ("active")
    return status in allowed
    # === fixed
    allowed = ("active",)
    return status in allowed
    # === alt: compares the status with the one allowed value
    return status == "active"
    # === wrong: refuses — lets no account sign in
    return False
    # === wrong: partial — compares by identity
    return status is "active"
    # === wrong: partial — turns away an empty status only
    allowed = ("active")
    return bool(status) and status in allowed
    # <<<
