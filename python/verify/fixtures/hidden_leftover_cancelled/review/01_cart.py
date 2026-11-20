import asyncio


async def reserve(sku):
    """Returns sku once the stock is known."""
    await asyncio.Event().wait()
    return sku
