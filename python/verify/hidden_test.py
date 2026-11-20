import asyncio

import pytest

from review_koans.checks import raises, settle
from verify.child import MASTER, run_pytest

FIX = "Fix the bug in {review} in place. The hidden checks name what still fails."


def _paths(fixture: str) -> tuple[str, str]:
    folder = f"verify/fixtures/{fixture}"
    return f"{folder}/01_cart_test.py", f"{folder}/review/01_cart.py"


def _footer(fixture: str, message: str) -> str:
    koan, review = _paths(fixture)
    return (
        f"{message}\n{MASTER}\n"
        f"Write:        {review}\n"
        f"Exercised by: {koan}:6\n"
        f"    {FIX.format(review=review)}\n"
        "0 of 1 koans answered."
    )


def _run(fixture: str):
    koan, _ = _paths(fixture)
    return run_pytest(koan, verify=True)


def _kind_lines(fixture: str, kind: str) -> list[str]:
    koan, _ = _paths(fixture)
    return [f"KOANS-TEST {kind} {koan}:4", f"KOANS-RESULT {kind} {koan}:6"]


def _assert_kind(stdout: str, fixture: str, kind: str) -> None:
    lines = [line for line in stdout.splitlines() if line.startswith("KOANS-")]
    assert lines == _kind_lines(fixture, kind)


def test_exploit_failure_shows_the_label_only():
    done = _run("hidden_exploit")
    assert done.returncode == 1
    assert _footer("hidden_exploit", "A hidden case still fails: an empty add") in done.stdout
    assert "ZX-99" not in done.stdout + done.stderr
    assert "assert " not in done.stdout + done.stderr
    _assert_kind(done.stdout, "hidden_exploit", "HiddenCase:exploit")


def test_twin_failure_is_reported_as_twin():
    done = _run("hidden_twin")
    assert _footer("hidden_twin", "A hidden case still fails: adding an item") in done.stdout
    assert "PEAR-7" not in done.stdout
    _assert_kind(done.stdout, "hidden_twin", "HiddenCase:twin")


def test_a_raise_in_the_learners_code_names_the_exception_only():
    done = _run("hidden_raised")
    message = "A hidden case still fails: an unknown item (it raised KeyError)"
    assert _footer("hidden_raised", message) in done.stdout
    assert "GHOST-1" not in done.stdout + done.stderr
    _assert_kind(done.stdout, "hidden_raised", "HiddenCase:exploit")


def test_a_system_exit_in_the_learners_code_is_reported_as_exited():
    done = _run("hidden_exited")
    message = "A hidden case still fails: an unknown item (it exited)"
    assert _footer("hidden_exited", message) in done.stdout
    _assert_kind(done.stdout, "hidden_exited", "HiddenCase:exploit")


def test_a_coroutine_that_never_finishes_fails_its_case_and_the_run_ends():
    done = _run("hidden_async_hang")
    message = "A hidden case still fails: a reservation that never finishes"
    assert _footer("hidden_async_hang", message) in done.stdout
    _assert_kind(done.stdout, "hidden_async_hang", "HiddenCase:exploit")


def test_a_task_that_swallows_cancellation_cannot_hang_the_run():
    done = _run("hidden_cancel_swallowed")
    message = "A hidden case still fails: a reservation that never finishes"
    assert _footer("hidden_cancel_swallowed", message) in done.stdout
    assert "destroyed" not in done.stdout + done.stderr
    _assert_kind(done.stdout, "hidden_cancel_swallowed", "HiddenCase:exploit")


def test_a_review_that_does_not_load_names_the_file_to_fix():
    done = _run("hidden_syntax")
    koan, review = _paths("hidden_syntax")
    assert f"\n{review} does not load: SyntaxError: " in done.stdout
    assert (
        f"\n{MASTER}\nWrite:        {review}\nExercised by: {koan}:6\n" in done.stdout
    )
    _assert_kind(done.stdout, "hidden_syntax", "ReviewDidNotLoad")


def test_each_case_gets_a_fresh_module():
    done = _run("hidden_fresh_state")
    assert done.returncode == 0
    koan, _ = _paths("hidden_fresh_state")
    assert f"KOANS-TEST ok {koan}:4" in done.stdout


def test_a_never_awaited_coroutine_warning_does_not_reach_the_output():
    done = _run("hidden_never_awaited")
    message = "A hidden case still fails: the warehouse is never told"
    assert _footer("hidden_never_awaited", message) in done.stdout
    assert "RuntimeWarning" not in done.stdout + done.stderr
    assert "warnings summary" not in done.stdout


def test_settle_returns_true_when_done_and_false_after_its_turns():
    async def scenario():
        quick = asyncio.create_task(asyncio.sleep(0))
        never = asyncio.create_task(asyncio.Event().wait())
        finished = await settle(quick)
        stuck = await settle(never, turns=3)
        never.cancel()
        return finished, stuck

    assert asyncio.run(scenario()) == (True, False)


def test_settle_uses_no_more_than_its_turns():
    async def scenario():
        turns = 0

        async def count():
            nonlocal turns
            while True:
                turns += 1
                await asyncio.sleep(0)

        counter = asyncio.create_task(count())
        await settle(asyncio.create_task(asyncio.Event().wait()), turns=5)
        counter.cancel()
        return turns

    assert asyncio.run(scenario()) <= 6


def test_raises_accepts_the_named_type_and_rejects_others():
    with raises(KeyError, ValueError):
        raise ValueError("accepted")
    with pytest.raises(AssertionError) as nothing:
        with raises(KeyError):
            pass
    assert str(nothing.value) == ""
    with pytest.raises(AssertionError) as other:
        with raises(KeyError):
            raise TypeError("rejected")
    assert str(other.value) == ""
    assert other.value.__suppress_context__
