def drop_expired(sessions):
    for token, session in sessions.items():
        if session["expired"]:
            del sessions[token]
    return sessions


sessions = {
    "a1": {"expired": False},
    "b2": {"expired": True},
    "c3": {"expired": False},
}
drop_expired(sessions)
