"""Accounts. find_email looks up a user's email address by name."""


def find_email(conn, name: str) -> list[tuple[str]]:
    """Returns the matching rows from the users table of the sqlite3 connection conn."""
    sql = "SELECT email FROM users WHERE name = ?"
    return conn.execute(sql, (name,)).fetchall()
