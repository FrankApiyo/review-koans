"""Handlers that record each event they receive, with the name it was registered under."""

from collections.abc import Callable


def build_handlers(names: list[str], log: list[tuple[str, str]]) -> dict[str, Callable[[str], None]]:
    handlers = {}
    for name in names:
        # >>> fix
        handlers[name] = lambda event: log.append((name, event))
        # === fixed
        handlers[name] = lambda event, name=name: log.append((name, event))
        # === alt: functools.partial
        from functools import partial

        handlers[name] = partial(lambda bound, event: log.append((bound, event)), name)
        # === wrong: refuses — handlers that record nothing
        handlers[name] = lambda event: None
        # === wrong: partial — looks the name up by index when called
        i = names.index(name)
        handlers[name] = lambda event: log.append((names[i], event))
        # === wrong: partial — a nested def in the loop
        def handler(event):
            log.append((name, event))

        handlers[name] = handler
        # === wrong: partial — copies the name into another variable
        current = name
        handlers[name] = lambda event: log.append((current, event))
        # <<<
    return handlers
