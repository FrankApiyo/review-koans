import sqlite3
from contextlib import closing

from review_koans.checks import exploit, twin

USERS = [("ann", "ann@example.com"), ("O'Brien", "ob@example.com"), ("eve", "eve@example.com")]


class Spy:
    def __init__(self, target, sent):
        self._target = target
        self.sent = sent

    def execute(self, sql, parameters=(), /):
        self.sent.append((sql, parameters))
        return self._target.execute(sql, parameters)

    def cursor(self, *args, **kwargs):
        return Spy(self._target.cursor(*args, **kwargs), self.sent)

    def __getattr__(self, name):
        return getattr(self._target, name)


def users():
    conn = sqlite3.connect(":memory:")
    conn.execute("CREATE TABLE users (name TEXT, email TEXT)")
    conn.executemany("INSERT INTO users VALUES (?, ?)", USERS)
    return conn


def found(review, name):
    with closing(users()) as conn:
        return review.find_email(conn, name)


def sent_for(review, name):
    sent = []
    with closing(users()) as conn:
        review.find_email(Spy(conn, sent), name)
    assert sent
    return sent


def values(parameters):
    return list(parameters.values()) if isinstance(parameters, dict) else list(parameters)


def plain(review):
    assert found(review, "ann") == [("ann@example.com",)]
    assert found(review, "zed") == []


def apostrophe(review):
    assert found(review, "O'Brien") == [("ob@example.com",)]


def every_row(review):
    assert found(review, "x' OR '1'='1") == []


def statement(review):
    quoted, plain_name = sent_for(review, "O'Brien"), sent_for(review, "ann")
    assert [sql for sql, _ in quoted] == [sql for sql, _ in plain_name]
    assert any("O'Brien" in values(parameters) for _, parameters in quoted)


CASES = [
    twin("a plain name", plain),
    exploit("a name with an apostrophe", apostrophe),
    exploit("a name written to match every row", every_row),
    exploit("the statement the database is sent", statement),
]
