"""Temp-file clean-up. discard deletes the file at path; a file that is already gone is not an error."""

import contextlib
import os


def discard(path: str) -> None:
    """Raises OSError when the path exists but cannot be deleted."""
    with contextlib.suppress(FileNotFoundError):
        os.unlink(path)
