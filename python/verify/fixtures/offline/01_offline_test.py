import socket


def test_loopback_connect():
    """A koan cannot open a connection, not even to this machine."""
    with socket.socket() as sock:
        sock.connect(("127.0.0.1", 9))


def test_create_connection():
    """A koan cannot reach a host by name either."""
    socket.create_connection(("localhost", 9))
