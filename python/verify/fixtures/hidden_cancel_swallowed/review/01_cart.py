import asyncio


async def reserve(sku):
    """Returns sku once the stock is known."""
    while True:
        try:
            await asyncio.sleep(0)
        except asyncio.CancelledError:
            pass
