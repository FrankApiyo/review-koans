"""App start-up. load_config reads the JSON settings file at path."""

import json


def load_config(path, opener=open):
    """Returns the parsed settings. Raises ValueError when the file is not valid JSON."""
    with opener(path) as f:
        data = json.load(f)
    return data
