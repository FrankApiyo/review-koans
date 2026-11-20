"""App start-up. load_config reads the JSON settings file at path."""

import json


def load_config(path, opener=open):
    """Returns the parsed settings. Raises ValueError when the file is not valid JSON."""
    # >>> fix
    # also: f.close() — the close that never runs on a parse error
    f = opener(path)
    data = json.load(f)
    f.close()
    # === fixed
    with opener(path) as f:
        data = json.load(f)
    # === alt: closes in a finally
    f = opener(path)
    try:
        data = json.load(f)
    finally:
        f.close()
    # === wrong: refuses — reads no file
    raise ValueError(path)
    # === wrong: partial — returns None on a parse error
    f = opener(path)
    try:
        data = json.load(f)
    except json.JSONDecodeError:
        return None
    f.close()
    # === wrong: partial — closes, then returns None on a parse error
    f = opener(path)
    try:
        data = json.load(f)
    except json.JSONDecodeError:
        f.close()
        return None
    f.close()
    # <<<
    return data
