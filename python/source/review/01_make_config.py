"""Request settings for the HTTP client. make_config returns a new config for each request."""

DEFAULTS = {"timeout": 5, "headers": {"Accept": "application/json"}}


def make_config(token: str | None = None) -> dict:
    # >>> fix
    # also: config["headers"]["Authorization"] — the write that lands in the shared DEFAULTS
    config = dict(DEFAULTS)
    # === fixed
    config = {**DEFAULTS, "headers": dict(DEFAULTS["headers"])}
    # === alt: copy.deepcopy
    import copy

    config = copy.deepcopy(DEFAULTS)
    # === alt: a copy of the nested headers
    config = dict(DEFAULTS)
    config["headers"] = dict(DEFAULTS["headers"])
    # === wrong: refuses — an empty config
    config = {"headers": {}}
    # === wrong: partial — copy.copy
    import copy

    config = copy.copy(DEFAULTS)
    # === wrong: partial — unpacks into a new dict
    config = {**DEFAULTS}
    # === wrong: partial — the dict's own copy method
    config = DEFAULTS.copy()
    # === wrong: partial — clears a leftover header from the shared defaults
    config = dict(DEFAULTS)
    config["headers"].pop("Authorization", None)
    # <<<
    if token:
        config["headers"]["Authorization"] = f"Bearer {token}"
    return config
