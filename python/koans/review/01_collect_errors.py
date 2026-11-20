"""Checks run on contact records before an import.

collect_errors adds a message for a record with no email. Pass it a list to gather the
messages for several records in that list.
"""


def collect_errors(record: dict[str, object], errors: list[str] = []) -> list[str]:
    if not record.get("email"):
        errors.append(f"{record['id']}: missing email")
    return errors
