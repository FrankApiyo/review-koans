"""HTTP status mapping. status_for runs an operation and returns the status code for its outcome."""


class NotFound(LookupError):
    pass


def status_for(op) -> int:
    """200 on success, 400 for a ValueError, 404 for NotFound and 500 for any other exception."""
    try:
        op()
        return 200
    # >>> fix
    except Exception:
        return 500
    except ValueError:
        return 400
    except NotFound:
        return 404
    # === fixed
    except ValueError:
        return 400
    except NotFound:
        return 404
    except Exception:
        return 500
    # === alt: one handler that matches on the type
    except Exception as error:
        match error:
            case ValueError():
                return 400
            case NotFound():
                return 404
            case _:
                return 500
    # === wrong: refuses — one status for every failure
    except Exception:
        return 400
    # === wrong: partial — moves the ValueError handler up only
    except ValueError:
        return 400
    except Exception:
        return 500
    except NotFound:
        return 404
    # === wrong: partial — moves the NotFound handler up only
    except NotFound:
        return 404
    except Exception:
        return 500
    except ValueError:
        return 400
    # === wrong: partial — 404 for every LookupError
    except ValueError:
        return 400
    except LookupError:
        return 404
    except Exception:
        return 500
    # <<<
