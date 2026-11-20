"""Persistence. save_all stores every item through the repository before it returns."""


async def save_all(repo, items) -> None:
    # >>> fix
    for item in items:
        repo.save(item)
    # === fixed
    for item in items:
        await repo.save(item)
    # === alt: asyncio.gather
    import asyncio

    await asyncio.gather(*(repo.save(item) for item in items))
    # === wrong: refuses — rejects every batch
    raise ValueError(items)
    # === wrong: partial — starts a task per item and returns
    import asyncio

    for item in items:
        asyncio.create_task(repo.save(item))
    # === wrong: partial — gathers without awaiting
    import asyncio

    asyncio.gather(*(repo.save(item) for item in items))
    # <<<
