import asyncio


async def charge(order_id, amount):
    await asyncio.sleep(0)
    if amount <= 0:
        raise ValueError(f"order {order_id}: amount must be positive, got {amount}")
    return order_id


async def charge_all(orders):
    async with asyncio.TaskGroup() as group:
        for order_id, amount in orders:
            group.create_task(charge(order_id, amount))


asyncio.run(charge_all([("o-1", 30), ("o-2", 0), ("o-3", 12)]))
