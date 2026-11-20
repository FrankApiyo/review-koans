import contextvars
import ipaddress
import socket
from collections.abc import Callable
from typing import Any, NoReturn

import pytest

_PAIRING = contextvars.ContextVar("pairing", default=False)
_LOOPBACK_NAMES = frozenset({None, "localhost", b"localhost"})


def _is_loopback_host(host: object) -> bool:
    if host in _LOOPBACK_NAMES:
        return True
    try:
        text = host.decode("ascii") if isinstance(host, bytes) else str(host)
        return ipaddress.ip_address(text.partition("%")[0]).is_loopback
    except (UnicodeDecodeError, ValueError):
        return False


def _is_loopback(address: object) -> bool:
    try:
        return ipaddress.ip_address(address[0]).is_loopback  # type: ignore[index]
    except (TypeError, ValueError, IndexError):
        return False


def _refuse(*_args: object, **_kwargs: object) -> NoReturn:
    raise RuntimeError("koans are offline")


def _loopback_only(lookup: Callable[..., Any]) -> Callable[..., Any]:
    def guarded(host: object, *args: object, **kwargs: object) -> Any:
        if not _is_loopback_host(host):
            _refuse()
        return lookup(host, *args, **kwargs)

    return guarded


@pytest.fixture(autouse=True)
def no_network(monkeypatch: pytest.MonkeyPatch) -> None:
    make_pair = socket.socketpair
    connect = socket.socket.connect
    connect_ex = socket.socket.connect_ex

    # On Windows, socketpair (which asyncio's event loop needs) is built from
    # a loopback connect, so a connect is allowed only there.
    def connect_within_pair(sock: socket.socket, address: object) -> None:
        if not (_PAIRING.get() and _is_loopback(address)):
            _refuse()
        connect(sock, address)

    def connect_ex_within_pair(sock: socket.socket, address: object) -> int:
        if not (_PAIRING.get() and _is_loopback(address)):
            _refuse()
        return connect_ex(sock, address)

    def local_pair(*args: object, **kwargs: object) -> tuple[socket.socket, socket.socket]:
        token = _PAIRING.set(True)
        try:
            return make_pair(*args, **kwargs)
        finally:
            _PAIRING.reset(token)

    monkeypatch.setattr(socket.socket, "connect", connect_within_pair)
    monkeypatch.setattr(socket.socket, "connect_ex", connect_ex_within_pair)
    monkeypatch.setattr(socket, "socketpair", local_pair)
    for name in ("getaddrinfo", "gethostbyname", "gethostbyname_ex"):
        monkeypatch.setattr(socket, name, _loopback_only(getattr(socket, name)))
