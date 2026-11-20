"""Outbound calls. with_retry awaits call and retries a ConnectionError, waiting longer each time."""

import asyncio
import time


async def with_retry(call, attempts=3, backoff=0.5):
    """Waits backoff * 2 ** attempt seconds between attempts; re-raises the last ConnectionError."""
    for attempt in range(attempts):
        try:
            return await call()
        except ConnectionError:
            if attempt == attempts - 1:
                raise
            # >>> fix
            time.sleep(backoff * 2 ** attempt)
            # === fixed
            await asyncio.sleep(backoff * 2 ** attempt)
            # === wrong: refuses — gives up on the first failure
            raise
            # === wrong: partial — waits in a worker thread
            await asyncio.to_thread(time.sleep, backoff * 2 ** attempt)
            # === wrong: partial — retries without waiting
            continue
            # <<<
