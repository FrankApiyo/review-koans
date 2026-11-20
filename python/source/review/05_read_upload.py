"""Uploads. read_upload returns the text of a file a user uploaded earlier."""

import os


def read_upload(base: str, name: str) -> str:
    """Reads the file name inside the folder base. Raises PermissionError when name points outside base."""
    # >>> fix
    return open(os.path.join(base, name)).read()
    # === fixed
    from pathlib import Path

    folder = Path(base).resolve()
    target = (folder / name).resolve()
    if not target.is_relative_to(folder):
        raise PermissionError(name)
    return target.read_text(encoding="utf-8")
    # === alt: os.path.commonpath
    folder = os.path.realpath(base)
    target = os.path.realpath(os.path.join(folder, name))
    if os.path.commonpath([folder, target]) != folder:
        raise PermissionError(name)
    with open(target, encoding="utf-8") as file:
        return file.read()
    # === wrong: refuses — reads nothing
    raise PermissionError(name)
    # === wrong: partial — refuses names with two dots in them
    if ".." in name:
        raise PermissionError(name)
    with open(os.path.join(base, name), encoding="utf-8") as file:
        return file.read()
    # === wrong: partial — compares the start of the path
    folder = os.path.realpath(base)
    target = os.path.realpath(os.path.join(folder, name))
    if not target.startswith(folder):
        raise PermissionError(name)
    with open(target, encoding="utf-8") as file:
        return file.read()
    # === wrong: partial — refuses names that start outside the folder
    if name.startswith(("..", "/")):
        raise PermissionError(name)
    with open(os.path.join(base, name), encoding="utf-8") as file:
        return file.read()
    # <<<
