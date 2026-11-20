import contextvars
import ipaddress
import socket
from typing import NoReturn

import pytest

_PAIRING = contextvars.ContextVar("pairing", default=False)


def _is_loopback(address: object) -> bool:
    try:
        return ipaddress.ip_address(address[0]).is_loopback  # type: ignore[index]
    except (TypeError, ValueError, IndexError):
        return False


def _refuse(*_args: object, **_kwargs: object) -> NoReturn:
    raise RuntimeError("koans are offline")


@pytest.fixture(autouse=True)
def no_network(monkeypatch: pytest.MonkeyPatch) -> None:
    make_pair = socket.socketpair
    connect = socket.socket.connect

    # On Windows, socketpair (which asyncio's event loop needs) is built from
    # a loopback connect, so a connect is allowed only there.
    def connect_within_pair(sock: socket.socket, address: object) -> None:
        if not (_PAIRING.get() and _is_loopback(address)):
            _refuse()
        connect(sock, address)

    def local_pair(*args: object, **kwargs: object) -> tuple[socket.socket, socket.socket]:
        token = _PAIRING.set(True)
        try:
            return make_pair(*args, **kwargs)
        finally:
            _PAIRING.reset(token)

    monkeypatch.setattr(socket.socket, "connect", connect_within_pair)
    monkeypatch.setattr(socket, "create_connection", _refuse)
    monkeypatch.setattr(socket, "socketpair", local_pair)
