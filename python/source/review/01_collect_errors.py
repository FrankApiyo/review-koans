"""Checks run on contact records before an import.

collect_errors adds a message for a record with no email. Pass it a list to gather the
messages for several records in that list.
"""


# >>> fix
def collect_errors(record: dict[str, object], errors: list[str] = []) -> list[str]:
# === fixed
def collect_errors(record: dict[str, object], errors: list[str] | None = None) -> list[str]:
    if errors is None:
        errors = []
# === alt: a conditional expression on the None sentinel
def collect_errors(record: dict[str, object], errors: list[str] | None = None) -> list[str]:
    errors = [] if errors is None else errors
# === wrong: refuses — returns a list of its own every time
def collect_errors(record: dict[str, object], errors: list[str] | None = None) -> list[str]:
    errors = []
# === wrong: partial — swaps an empty caller list for a new one
def collect_errors(record: dict[str, object], errors: list[str] | None = None) -> list[str]:
    errors = errors or []
# === wrong: partial — copies the caller's list
def collect_errors(record: dict[str, object], errors: tuple[str, ...] | list[str] = ()) -> list[str]:
    errors = list(errors)
# === wrong: partial — copies the caller's list or starts an empty one
def collect_errors(record: dict[str, object], errors: list[str] | None = None) -> list[str]:
    errors = list(errors or [])
# <<<
    if not record.get("email"):
        errors.append(f"{record['id']}: missing email")
    return errors
