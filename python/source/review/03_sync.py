"""Outbox sync. sync pushes each id and returns the ids whose push failed, in order."""


def sync(ids: list[int], push) -> list[int]:
    failed = []
    for i in ids:
        try:
            push(i)
        # >>> fix
        except Exception:
            continue
        # === fixed
        except Exception:
            failed.append(i)
        # === alt: records the id, then continues
        except Exception:
            failed.append(i)
            continue
        # === alt: extends the list
        except Exception:
            failed += [i]
        # === wrong: refuses — reports every id
        except Exception:
            pass
        failed.append(i)
        # === wrong: partial — records the id, then stops
        except Exception:
            failed.append(i)
            break
        # === wrong: partial — returns at the first failure
        except Exception:
            failed.append(i)
            return failed
        # === wrong: partial — keeps the latest failure only
        except Exception:
            failed = [i]
        # <<<
    return failed
