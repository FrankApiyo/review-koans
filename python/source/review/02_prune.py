"""Settings clean-up. prune deletes the settings whose value is None and returns the same dict."""


def prune(settings: dict[str, object]) -> dict[str, object]:
    # >>> guard
    for key in list(settings):
        if settings[key] is None:
            del settings[key]
    return settings
    # === wrong: partial — iterates the dict itself
    for key in settings:
        if settings[key] is None:
            del settings[key]
    return settings
    # === wrong: partial — iterates the dict's items
    for key, value in settings.items():
        if value is None:
            del settings[key]
    return settings
    # === wrong: partial — returns a new dict
    return {key: value for key, value in settings.items() if value is not None}
    # <<<
