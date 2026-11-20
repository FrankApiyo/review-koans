"""
Look for: a call to an `async def` with no `await` in front of it, in a statement or an `if`; a
blocking call such as the `time` module's `sleep` inside `async def`; `gather` where one failure
should stop the rest; an `except` around an `await` that catches cancellation and carries on.

Why it bites: calling an `async def` only builds a coroutine object. Nothing in it runs until it
is awaited, and the object is always true, so a check written without `await` always passes. A
blocking call stops the event loop, and every other task waits with it. `gather` hands its caller
the first error but leaves the other awaitables running (asyncio's documented choice), so they can
commit after the request failed. A `TaskGroup` wraps its tasks' errors in an `ExceptionGroup`.
Cancellation arrives as `CancelledError` at an `await`. It has been a `BaseException` since 3.8,
so `except Exception` lets it through, but a bare `except` does not. The default event loop runs
ready callbacks in the order they were scheduled, which asyncio documents; `gather` returns its
results in argument order, whatever order they finish in.

Review habit: Ask what happens on crash. At each `await`, ask what becomes of the work already
started if this line raises or the task is cancelled: does it stop, keep running, or commit anyway?

A common mistake: starting a task and not awaiting it, so the function returns before the work
runs; `return_exceptions=True`, which still waits for the slow job; `break` or `return` on cancel,
which ends the task normally, and `TaskGroup` and the `timeout()` context manager are built on
cancellation, so asyncio's docs say they misbehave when a task swallows it; moving the blocking call
into a worker thread, which frees the loop but ties up a thread; `as_completed`, which yields in
completion order. In the `04_charge_all` trace, the outer traceback ends at the group's line,
which only says where the group was; the order that failed is in the sub-exception.

Read more: https://docs.python.org/3.13/library/asyncio-task.html,
https://docs.python.org/3.13/library/asyncio-dev.html,
https://docs.python.org/3.13/library/asyncio-eventloop.html
"""

import asyncio

from review_koans import FINE, __, run_checks, trace, verdict


def test_save_all_verdict():
    """Read koans/review/04_save_all.py. Write FINE, or the line number of the bug."""
    verdict("04_save_all.py", _a(6))


def test_fix_save_all():
    """Fix the bug in koans/review/04_save_all.py in place. The hidden checks name what still fails."""
    run_checks(__file__, "04_save_all")


def test_gather_takes_turns():
    """Two workers run under gather and yield with sleep(0) after each step. In what order do the steps land?"""
    log = []

    async def worker(name, steps):
        for step in range(steps):
            log.append(f"{name}{step}")
            await asyncio.sleep(0)

    async def main():
        await asyncio.gather(worker("a", 2), worker("b", 3))

    asyncio.run(main())
    assert log == _a(["a0", "b0", "a1", "b1", "b2"])


def test_with_retry_verdict():
    """Read koans/review/04_with_retry.py. Write FINE, or the line number of the bug."""
    verdict("04_with_retry.py", _a(15))


def test_fix_with_retry():
    """Fix the bug in koans/review/04_with_retry.py in place. The hidden checks name what still fails."""
    run_checks(__file__, "04_with_retry")


def test_ship_all_verdict():
    """Read koans/review/04_ship_all.py. Write FINE, or the line number of the bug."""
    verdict("04_ship_all.py", _a(8))


def test_fix_ship_all():
    """Fix the bug in koans/review/04_ship_all.py in place. The hidden checks name what still fails."""
    run_checks(__file__, "04_ship_all")


def test_charge_all_trace():
    """Read traces/04_charge_all.py.trace. Name both exceptions in order, then the file and line that raised."""
    assert trace.exceptions("04_charge_all") == _a(["ExceptionGroup", "ValueError"])
    assert trace.crash_frame("04_charge_all") == _a(("traces/04_charge_all.py", 7))


def test_poll_verdict():
    """Read koans/review/04_poll.py. Write FINE, or the line number of the bug."""
    verdict("04_poll.py", _a(11))


def test_fix_poll():
    """Fix the bug in koans/review/04_poll.py in place. The hidden checks name what still fails."""
    run_checks(__file__, "04_poll")


def test_fetch_all_verdict_and_checks():
    """Read koans/review/04_fetch_all.py. Write FINE, or the line number of the bug."""
    verdict("04_fetch_all.py", _a(FINE))
    run_checks(__file__, "04_fetch_all")


def test_delete_note_verdict():
    """Read koans/review/04_delete_note.py. Write FINE, or the line number of the bug."""
    verdict("04_delete_note.py", _a(13))


def test_fix_delete_note():
    """Fix the bug in koans/review/04_delete_note.py in place. The hidden checks name what still fails."""
    run_checks(__file__, "04_delete_note")
