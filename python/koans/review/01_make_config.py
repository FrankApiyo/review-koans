"""Request settings for the HTTP client. make_config returns a new config for each request."""

DEFAULTS = {"timeout": 5, "headers": {"Accept": "application/json"}}


def make_config(token: str | None = None) -> dict:
    config = dict(DEFAULTS)
    if token:
        config["headers"]["Authorization"] = f"Bearer {token}"
    return config
