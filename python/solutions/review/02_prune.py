"""Settings clean-up. prune deletes the settings whose value is None and returns the same dict."""


def prune(settings: dict[str, object]) -> dict[str, object]:
    for key in list(settings):
        if settings[key] is None:
            del settings[key]
    return settings
