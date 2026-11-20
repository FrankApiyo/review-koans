import asyncio

from review_koans.checks import twin

cancelled = []


async def _hold(review):
    try:
        await review.reserve("PEAR-7")
    except asyncio.CancelledError:
        cancelled.append("PEAR-7")
        raise


async def leaves_a_task(review):
    asyncio.create_task(_hold(review))
    await asyncio.sleep(0)


def leftover_was_cancelled(review):
    assert cancelled == ["PEAR-7"]


CASES = [twin("a reservation", leaves_a_task), twin("a cancelled reservation", leftover_was_cancelled)]
