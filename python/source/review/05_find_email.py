"""Accounts. find_email looks up a user's email address by name."""


def find_email(conn, name: str) -> list[tuple[str]]:
    """Returns the matching rows from the users table of the sqlite3 connection conn."""
    # >>> fix
    sql = f"SELECT email FROM users WHERE name = '{name}'"
    return conn.execute(sql).fetchall()
    # === fixed
    sql = "SELECT email FROM users WHERE name = ?"
    return conn.execute(sql, (name,)).fetchall()
    # === alt: a named parameter
    sql = "SELECT email FROM users WHERE name = :name"
    return conn.execute(sql, {"name": name}).fetchall()
    # === wrong: refuses — finds nobody
    return []
    # === wrong: partial — strips quotes
    name = name.replace("'", "")
    sql = f"SELECT email FROM users WHERE name = '{name}'"
    return conn.execute(sql).fetchall()
    # === wrong: partial — doubles quotes
    name = name.replace("'", "''")
    sql = f"SELECT email FROM users WHERE name = '{name}'"
    return conn.execute(sql).fetchall()
    # === wrong: partial — escapes quotes with a backslash
    name = name.replace("'", "\\'")
    sql = f"SELECT email FROM users WHERE name = '{name}'"
    return conn.execute(sql).fetchall()
    # <<<
