"""Service settings. load_port reads the port to listen on from a config dict."""


def load_port(cfg: dict) -> int:
    """Returns 8080 when the config has no port. Raises ValueError when the port is not a whole number."""
    # >>> fix
    try:
        return int(cfg["port"])
    except Exception:
        return 8080
    # === fixed
    try:
        return int(cfg["port"])
    except KeyError:
        return 8080
    # === alt: a default for the lookup
    return int(cfg.get("port", 8080))
    # === alt: the lookup alone in the try
    try:
        port = cfg["port"]
    except KeyError:
        return 8080
    return int(port)
    # === wrong: refuses — accepts no config
    raise ValueError("no usable port")
    # === wrong: partial — catches ValueError with the missing key
    try:
        return int(cfg["port"])
    except (KeyError, ValueError):
        return 8080
    # === wrong: partial — checks for the key, keeps the broad handler
    if "port" not in cfg:
        return 8080
    try:
        return int(cfg["port"])
    except Exception:
        return 8080
    # === wrong: partial — falls back on any empty port
    return int(cfg.get("port") or 8080)
    # <<<
