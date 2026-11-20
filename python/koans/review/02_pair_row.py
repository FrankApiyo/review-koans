"""CSV import. pair_row pairs each header with the value in the same column."""


def pair_row(headers: list[str], values: list[str]) -> dict[str, str]:
    """Raises ValueError when the lengths differ."""
    return dict(zip(headers, values))
