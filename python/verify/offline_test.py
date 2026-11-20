import asyncio
import socket

import pytest

from verify.child import MASTER, run_pytest

OFFLINE = "verify/fixtures/offline/01_offline_test.py"


def test_a_tcp_connect_is_refused_inside_a_koan():
    done = run_pytest("verify/fixtures/offline", verify=True)
    assert f"KOANS-TEST RuntimeError {OFFLINE}:4" in done.stdout
    assert f"KOANS-TEST RuntimeError {OFFLINE}:10" in done.stdout
    assert f"RuntimeError: koans are offline\n{MASTER}\nMeditate on {OFFLINE}:7\n" in done.stdout


def test_asyncio_run_still_works():
    with pytest.raises(RuntimeError, match="koans are offline"):
        socket.create_connection(("127.0.0.1", 9))

    async def answer():
        await asyncio.sleep(0)
        return 42

    assert asyncio.run(answer()) == 42
    left, right = socket.socketpair()
    with left, right:
        left.sendall(b"x")
        assert right.recv(1) == b"x"
