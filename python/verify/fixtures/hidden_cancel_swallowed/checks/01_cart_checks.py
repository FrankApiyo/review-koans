import asyncio

from review_koans.checks import exploit, settle


async def finishes(review):
    task = asyncio.create_task(review.reserve("PEAR-7"))
    assert await settle(task)


CASES = [exploit("a reservation that never finishes", finishes)]
