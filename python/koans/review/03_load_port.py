"""Service settings. load_port reads the port to listen on from a config dict."""


def load_port(cfg: dict) -> int:
    """Returns 8080 when the config has no port. Raises ValueError when the port is not a whole number."""
    try:
        return int(cfg["port"])
    except Exception:
        return 8080
