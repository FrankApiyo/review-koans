"""CSV import. pair_row pairs each header with the value in the same column."""


def pair_row(headers: list[str], values: list[str]) -> dict[str, str]:
    """Raises ValueError when the lengths differ."""
    # >>> fix
    return dict(zip(headers, values))
    # === fixed
    return dict(zip(headers, values, strict=True))
    # === alt: an explicit length check
    if len(headers) != len(values):
        raise ValueError(f"{len(headers)} headers, {len(values)} values")
    return dict(zip(headers, values))
    # === wrong: refuses — rejects every row
    raise ValueError("row does not match the headers")
    # === wrong: partial — itertools.zip_longest
    from itertools import zip_longest

    return dict(zip_longest(headers, values))
    # === wrong: partial — rejects a row with too many values only
    if len(values) > len(headers):
        raise ValueError(f"{len(headers)} headers, {len(values)} values")
    return dict(zip(headers, values))
    # === wrong: partial — rejects a row with too few values only
    if len(values) < len(headers):
        raise ValueError(f"{len(headers)} headers, {len(values)} values")
    return dict(zip(headers, values))
    # <<<
