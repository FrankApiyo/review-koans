"""Health checks. poll awaits check every interval seconds until stop is set; cancelling the poller stops it."""

import asyncio


async def poll(check, stop, interval):
    while not stop.is_set():
        await check()
        try:
            await asyncio.sleep(interval)
        # >>> fix
        except asyncio.CancelledError:
            pass
        # === fixed
        except asyncio.CancelledError:
            raise
        # === alt: catches Exception, which CancelledError is not
        except Exception:
            pass
        # === wrong: refuses — stops after the first check
        finally:
            stop.set()
        # === wrong: partial — leaves the loop on cancel
        except asyncio.CancelledError:
            break
        # === wrong: partial — sets stop on cancel
        except asyncio.CancelledError:
            stop.set()
        # === wrong: partial — a bare except
        except:
            pass
        # <<<
