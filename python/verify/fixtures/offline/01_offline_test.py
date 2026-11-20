import socket


def test_loopback_connect():
    """A koan cannot open a connection, not even to this machine."""
    with socket.socket() as sock:
        sock.connect(("127.0.0.1", 9))


def test_create_connection():
    """A koan cannot reach a host by name either."""
    socket.create_connection(("localhost", 9))


def test_connect_ex():
    """connect_ex is a connect too."""
    with socket.socket() as sock:
        sock.connect_ex(("127.0.0.1", 9))


def test_getaddrinfo():
    """A koan cannot look up a name."""
    socket.getaddrinfo("example.invalid", 80)


def test_gethostbyname():
    """Nor through the older lookup."""
    socket.gethostbyname("example.invalid")


def test_gethostbyname_ex():
    """Nor through its extended form."""
    socket.gethostbyname_ex("example.invalid")


def test_open_connection():
    """asyncio resolves names through the same lookup."""
    import asyncio

    asyncio.run(asyncio.open_connection("example.invalid", 80))
