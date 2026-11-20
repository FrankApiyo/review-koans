"""HTTP status mapping. status_for runs an operation and returns the status code for its outcome."""


class NotFound(LookupError):
    pass


def status_for(op) -> int:
    """200 on success, 400 for a ValueError, 404 for NotFound and 500 for any other exception."""
    try:
        op()
        return 200
    except ValueError:
        return 400
    except NotFound:
        return 404
    except Exception:
        return 500
