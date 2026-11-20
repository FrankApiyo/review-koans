"""Notes. delete_note removes a note from the store; only an admin may delete."""

import asyncio


async def is_admin(user) -> bool:
    await asyncio.sleep(0)
    return user["role"] == "admin"


async def delete_note(user, note, store) -> None:
    """Raises PermissionError naming the user when they are not an admin."""
    if not await is_admin(user):
        raise PermissionError(user["name"])
    store.discard(note)
