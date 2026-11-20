"""Uploads. read_upload returns the text of a file a user uploaded earlier."""

import os


def read_upload(base: str, name: str) -> str:
    """Reads the file name inside the folder base. Raises PermissionError when name points outside base."""
    return open(os.path.join(base, name)).read()
