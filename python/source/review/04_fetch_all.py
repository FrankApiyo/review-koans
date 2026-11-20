"""Catalogue reads. fetch_all fetches every id at once and returns the results in the order of ids."""

import asyncio


async def fetch_all(fetch, ids):
    # >>> guard
    return await asyncio.gather(*(fetch(i) for i in ids))
    # === wrong: partial — collects with asyncio.as_completed
    return [await result for result in asyncio.as_completed([fetch(i) for i in ids])]
    # === wrong: partial — appends each result as it arrives
    results = []

    async def one(i):
        results.append(await fetch(i))

    async with asyncio.TaskGroup() as group:
        for i in ids:
            group.create_task(one(i))
    return results
    # <<<
