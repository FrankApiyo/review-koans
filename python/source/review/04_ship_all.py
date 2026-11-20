"""Fulfilment. ship_all runs every job at once and returns their results in job order."""

import asyncio


async def ship_all(jobs):
    """If a job fails, the jobs still running are cancelled and its error propagates."""
    # >>> fix
    return await asyncio.gather(*(job() for job in jobs))
    # === fixed
    async with asyncio.TaskGroup() as group:
        tasks = [group.create_task(job()) for job in jobs]
    return [task.result() for task in tasks]
    # === alt: asyncio.wait with FIRST_EXCEPTION, then cancel the rest
    tasks = [asyncio.create_task(job()) for job in jobs]
    done, pending = await asyncio.wait(tasks, return_when=asyncio.FIRST_EXCEPTION)
    for task in pending:
        task.cancel()
    for task in done:
        if task.exception() is not None:
            raise task.exception()
    return [task.result() for task in tasks]
    # === wrong: refuses — runs no job
    return []
    # === wrong: partial — collects errors instead of raising
    return await asyncio.gather(*(job() for job in jobs), return_exceptions=True)
    # === wrong: partial — cancels the gather once it has failed
    running = asyncio.gather(*(job() for job in jobs))
    try:
        return await running
    except Exception:
        running.cancel()
        raise
    # <<<
