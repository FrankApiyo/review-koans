import asyncio

from review_koans.checks import exploit, settle, twin


async def turns(count):
    for _ in range(count):
        await asyncio.sleep(0)


async def stops(review):
    stop, calls = asyncio.Event(), []

    async def check():
        calls.append(1)
        if len(calls) == 3:
            stop.set()

    task = asyncio.create_task(review.poll(check, stop, 0))
    assert await settle(task)
    assert task.result() is None
    assert len(calls) == 3


async def cancelled(review):
    stop = asyncio.Event()

    async def check():
        pass

    task = asyncio.create_task(review.poll(check, stop, 0))
    await turns(3)
    task.cancel()
    try:
        await settle(task, turns=10)
        assert task.cancelled()
    finally:
        stop.set()
        await settle(task)


CASES = [
    twin("a poller whose stop is set", stops),
    exploit("a poller that is cancelled", cancelled),
]
