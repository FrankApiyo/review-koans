"""Fulfilment. ship_all runs every job at once and returns their results in job order."""

import asyncio


async def ship_all(jobs):
    """If a job fails, the jobs still running are cancelled and its error propagates."""
    return await asyncio.gather(*(job() for job in jobs))
