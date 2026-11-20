import asyncio
import socket

import pytest

from verify.child import MASTER, run_pytest

OFFLINE = "verify/fixtures/offline/01_offline_test.py"
OFFLINE_KOANS = (4, 10, 15, 21, 26, 31, 36)


def test_a_tcp_connect_is_refused_inside_a_koan():
    done = run_pytest("verify/fixtures/offline", verify=True)
    tests = [line for line in done.stdout.splitlines() if line.startswith("KOANS-TEST")]
    assert tests == [f"KOANS-TEST RuntimeError {OFFLINE}:{line}" for line in OFFLINE_KOANS]
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
    assert socket.gethostbyname("127.0.0.1") == "127.0.0.1"
    assert socket.gethostbyname_ex("127.0.0.2")[2] == ["127.0.0.2"]
    assert {info[4][0] for info in socket.getaddrinfo("::1", 9)} == {"::1"}
    assert socket.getaddrinfo("localhost", 9)
    assert socket.getaddrinfo(None, 9)
