import asyncio

from review_koans.checks import exploit, settle, twin


class Repo:
    def __init__(self):
        self.saved = []

    async def save(self, item):
        await asyncio.sleep(0)
        self.saved.append(item)


async def saved_by(review, items):
    repo = Repo()
    task = asyncio.create_task(review.save_all(repo, items))
    assert await settle(task)
    assert task.result() is None
    return sorted(repo.saved)


async def empty_batch(review):
    assert await saved_by(review, []) == []


async def batch(review):
    assert await saved_by(review, ["a", "b"]) == ["a", "b"]


CASES = [
    twin("an empty batch", empty_batch),
    exploit("a batch of items", batch),
]
