import asyncio

from review_koans.checks import exploit, settle, twin


async def turns(count):
    for _ in range(count):
        await asyncio.sleep(0)


async def good_jobs(review):
    gate = asyncio.Event()

    async def first():
        await gate.wait()
        return 1

    async def second():
        gate.set()
        return 2

    task = asyncio.create_task(review.ship_all([first, second]))
    assert await settle(task)
    assert task.result() == [1, 2]


def holds_value_error(error):
    if isinstance(error, ExceptionGroup):
        return error.subgroup(ValueError) is not None
    return isinstance(error, ValueError)


async def one_fails(review, slow_first=False):
    gate, committed = asyncio.Event(), []

    async def fails():
        raise ValueError("label printer offline")

    async def slow():
        await gate.wait()
        committed.append("parcel-2")

    jobs = [slow, fails] if slow_first else [fails, slow]
    task = asyncio.create_task(review.ship_all(jobs))
    finished = await settle(task)
    gate.set()
    await turns(5)
    assert finished
    assert not task.cancelled() and holds_value_error(task.exception())
    assert committed == []


async def fails_after_slow(review):
    await one_fails(review, slow_first=True)


CASES = [
    twin("jobs that wait on each other and all succeed", good_jobs),
    exploit("a job that fails while another is still running", one_fails),
    exploit("a job that fails after a job listed before it", fails_after_slow),
]
