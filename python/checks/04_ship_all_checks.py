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


async def one_fails(review):
    gate, committed = asyncio.Event(), []

    async def fails():
        raise ValueError("label printer offline")

    async def slow():
        await gate.wait()
        committed.append("parcel-2")

    task = asyncio.create_task(review.ship_all([fails, slow]))
    finished = await settle(task)
    gate.set()
    await turns(5)
    assert finished
    assert not task.cancelled() and holds_value_error(task.exception())
    assert committed == []


CASES = [
    twin("jobs that wait on each other and all succeed", good_jobs),
    exploit("a job that fails while another is still running", one_fails),
]
