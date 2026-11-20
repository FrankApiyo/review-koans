import asyncio

from review_koans.checks import exploit, raises, settle, twin


async def deleted_by(review, user):
    store = {"n-1", "n-2"}
    task = asyncio.create_task(review.delete_note(user, "n-1", store))
    assert await settle(task)
    return task, store


async def admin(review):
    task, store = await deleted_by(review, {"name": "ann", "role": "admin"})
    assert task.result() is None
    assert store == {"n-2"}


async def viewer(review):
    task, store = await deleted_by(review, {"name": "eve", "role": "viewer"})
    with raises(PermissionError):
        task.result()
    assert store == {"n-1", "n-2"}


CASES = [
    twin("an admin deletes a note", admin),
    exploit("a viewer deletes a note", viewer),
]
