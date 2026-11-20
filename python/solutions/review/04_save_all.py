"""Persistence. save_all stores every item through the repository before it returns."""


async def save_all(repo, items) -> None:
    for item in items:
        await repo.save(item)
