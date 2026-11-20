"""Uploads. read_upload returns the text of a file a user uploaded earlier."""

import os


def read_upload(base: str, name: str) -> str:
    """Reads the file name inside the folder base. Raises PermissionError when name points outside base."""
    from pathlib import Path

    folder = Path(base).resolve()
    target = (folder / name).resolve()
    if not target.is_relative_to(folder):
        raise PermissionError(name)
    return target.read_text(encoding="utf-8")
