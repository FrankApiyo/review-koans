import asyncio
import time

from review_koans.checks import exploit, settle, twin


class Clock:
    def __init__(self):
        self.blocking = []
        self.log = []

    def blocking_sleep(self, seconds):
        self.blocking.append(seconds)


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
    loop = asyncio.get_running_loop()

    def call_later(delay, callback, *args, context=None):
        clock.log.append(delay)
        return loop.call_soon(callback, *args, context=context)

    async def run_in_executor(_executor, func, *args):
        return func(*args)

    loop.call_later, loop.run_in_executor = call_later, run_in_executor
    blocking_time = Proxy(time, sleep=clock.blocking_sleep)
    for name, value in list(vars(review).items()):
        if value is time:
            setattr(review, name, blocking_time)
        elif value is time.sleep:
            setattr(review, name, clock.blocking_sleep)
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
