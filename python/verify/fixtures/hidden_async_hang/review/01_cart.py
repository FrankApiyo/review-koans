import asyncio

_stocked = asyncio.Event()


async def reserve(sku):
    """Returns sku once the stock is known."""
    await _stocked.wait()
    return sku
