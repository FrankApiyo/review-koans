"""Temp-file clean-up. discard deletes the file at path; a file that is already gone is not an error."""

import contextlib
import os


def discard(path: str) -> None:
    """Raises OSError when the path exists but cannot be deleted."""
    # >>> guard
    with contextlib.suppress(FileNotFoundError):
        os.unlink(path)
    # === wrong: partial — suppresses every OSError
    with contextlib.suppress(OSError):
        os.unlink(path)
    # === wrong: partial — suppresses every Exception
    with contextlib.suppress(Exception):
        os.unlink(path)
    # <<<
