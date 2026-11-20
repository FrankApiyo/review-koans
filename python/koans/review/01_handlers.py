"""Handlers that record each event they receive, with the name it was registered under."""

from collections.abc import Callable


def build_handlers(names: list[str], log: list[tuple[str, str]]) -> dict[str, Callable[[str], None]]:
    handlers = {}
    for name in names:
        handlers[name] = lambda event: log.append((name, event))
    return handlers
