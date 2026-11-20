"""Health checks. poll awaits check every interval seconds until stop is set; cancelling the poller stops it."""

import asyncio


async def poll(check, stop, interval):
    while not stop.is_set():
        await check()
        try:
            await asyncio.sleep(interval)
        except asyncio.CancelledError:
            raise
