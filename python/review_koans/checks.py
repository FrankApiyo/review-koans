import asyncio
from collections.abc import Callable, Iterator
from contextlib import contextmanager
from dataclasses import dataclass
from types import ModuleType
from typing import Literal


@dataclass(frozen=True)
class Case:
    kind: Literal["twin", "exploit"]
    label: str
    run: Callable[[ModuleType], object]


def twin(label: str, run: Callable[[ModuleType], object]) -> Case:
    return Case("twin", label, run)


def exploit(label: str, run: Callable[[ModuleType], object]) -> Case:
    return Case("exploit", label, run)


@contextmanager
def raises(*types: type[BaseException]) -> Iterator[None]:
    try:
        yield
    except types:
        return
    except Exception:
        raise AssertionError from None
    raise AssertionError


async def settle(task: asyncio.Future[object], turns: int = 100) -> bool:
    for _ in range(turns):
        if task.done():
            break
        await asyncio.sleep(0)
    return task.done()
