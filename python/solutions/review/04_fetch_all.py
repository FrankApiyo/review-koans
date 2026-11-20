"""Catalogue reads. fetch_all fetches every id at once and returns the results in the order of ids."""

import asyncio


async def fetch_all(fetch, ids):
    return await asyncio.gather(*(fetch(i) for i in ids))
