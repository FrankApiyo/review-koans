import asyncio

from review_koans.checks import exploit, settle, twin


async def turns(count):
    for _ in range(count):
        await asyncio.sleep(0)


async def fetched(review, release_order):
    gates = {i: asyncio.Event() for i in "abc"}

    async def fetch(i):
        await gates[i].wait()
        return i.upper()

    task = asyncio.create_task(review.fetch_all(fetch, ["a", "b", "c"]))
    for i in release_order:
        await turns(5)
        gates[i].set()
    assert await settle(task)
    return task.result()


async def in_order(review):
    assert await fetched(review, "abc") == ["A", "B", "C"]


async def out_of_order(review):
    assert await fetched(review, "cba") == ["A", "B", "C"]


CASES = [
    twin("fetches that finish in order", in_order),
    exploit("fetches that finish in reverse order", out_of_order),
]
