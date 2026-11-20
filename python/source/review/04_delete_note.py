"""Notes. delete_note removes a note from the store; only an admin may delete."""

import asyncio


async def is_admin(user) -> bool:
    await asyncio.sleep(0)
    return user["role"] == "admin"


async def delete_note(user, note, store) -> None:
    """Raises PermissionError naming the user when they are not an admin."""
    # >>> fix
    if not is_admin(user):
    # === fixed
    if not await is_admin(user):
    # === alt: the awaited check in parentheses
    if not (await is_admin(user)):
    # === wrong: refuses — rejects every user
    if True:
    # === wrong: partial — compares the coroutine with False
    if is_admin(user) is False:
    # === wrong: partial — runs the check in a new event loop
    if not asyncio.run(is_admin(user)):
    # <<<
        raise PermissionError(user["name"])
    store.discard(note)
