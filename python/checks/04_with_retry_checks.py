import asyncio
import time

from review_koans.checks import exploit, settle, twin


class Clock:
    def __init__(self):
        self.blocking = []
        self.log = []

    def blocking_sleep(self, seconds):
        self.blocking.append(seconds)

    async def sleep(self, delay, result=None):
        await asyncio.sleep(0)
        self.log.append(delay)
        return result

    async def to_thread(self, func, /, *args, **kwargs):
        return func(*args, **kwargs)


class Proxy:
    def __init__(self, module, **replaced):
        self._module = module
        self.__dict__.update(replaced)

    def __getattr__(self, name):
        return getattr(self._module, name)


class Flaky:
    def __init__(self, log, failures, error=ConnectionError):
        self.log = log
        self.failures = failures
        self.error = error

    async def __call__(self):
        self.log.append("call")
        await asyncio.sleep(0)
        if self.failures:
            self.failures -= 1
            raise self.error
        return "ok"


def patch(review):
    clock = Clock()
    review.time = Proxy(time, sleep=clock.blocking_sleep)
    review.asyncio = Proxy(asyncio, sleep=clock.sleep, to_thread=clock.to_thread)
    swaps = {time.sleep: clock.blocking_sleep, asyncio.sleep: clock.sleep, asyncio.to_thread: clock.to_thread}
    for name in ("sleep", "to_thread"):
        if getattr(review, name, None) in swaps:
            setattr(review, name, swaps[getattr(review, name)])
    return clock


async def retried(review, failures, error=ConnectionError):
    clock = patch(review)
    task = asyncio.create_task(review.with_retry(Flaky(clock.log, failures, error)))
    assert await settle(task)
    return task, clock


async def first_try(review):
    task, clock = await retried(review, 0)
    assert task.result() == "ok"
    assert clock.log == ["call"]
    assert clock.blocking == []


async def second_try(review):
    task, _clock = await retried(review, 1)
    assert task.result() == "ok"


async def other_failure(review):
    task, clock = await retried(review, 1, ValueError)
    assert isinstance(task.exception(), ValueError)
    assert clock.log == ["call"]
    assert clock.blocking == []


async def fails_twice(review):
    task, clock = await retried(review, 2)
    assert task.result() == "ok"
    assert clock.blocking == []
    assert clock.log == ["call", 0.5, "call", 1.0, "call"]


CASES = [
    twin("a call that succeeds the first time", first_try),
    twin("a call that fails once before it succeeds", second_try),
    twin("a call that fails some other way", other_failure),
    exploit("a call that fails twice before it succeeds", fails_twice),
]
