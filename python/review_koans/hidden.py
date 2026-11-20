import asyncio
import gc
import importlib.util
import inspect
import itertools
import os
import sys
import warnings
from pathlib import Path
from types import ModuleType
from typing import Final

from review_koans.checks import Case, settle
from review_koans.verdict import review_path

_counter: Final = itertools.count()
_PASSED: Final = object()


class HiddenCase(AssertionError):
    def __init__(self, label: str, kind: str, review_path: str, cause: str | None) -> None:
        suffix = f" (it {cause})" if cause else ""
        super().__init__(f"A hidden case still fails: {label}{suffix}")
        self.label = label
        self.kind = kind
        self.review_path = review_path
        self.cause = cause


class ReviewDidNotLoad(Exception):
    def __init__(self, review_path: str, error: BaseException) -> None:
        lines = str(error).splitlines()
        reason = f"{type(error).__name__}: {lines[0]}" if lines else type(error).__name__
        super().__init__(f"{review_path} does not load: {reason}")
        self.review_path = review_path


def _load(path: str, prefix: str) -> ModuleType:
    name = f"_review_koans.{prefix}{next(_counter)}"
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise ImportError(f"cannot load {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    try:
        spec.loader.exec_module(module)
    except BaseException:
        del sys.modules[name]
        raise
    return module


def load_review(koan_file: str, stem: str) -> ModuleType:
    return _load(review_path(koan_file, f"{stem}.py"), "r")


def _checks_path(koan_file: str, stem: str) -> Path:
    start = Path(koan_file).resolve().parent
    for folder in (start, *start.parents):
        candidate = folder / "checks" / f"{stem}_checks.py"
        if candidate.is_file():
            return candidate
        if (folder / "conftest.py").is_file():
            break
    raise FileNotFoundError(f"no checks/{stem}_checks.py between {start} and the track root")


def load_checks(koan_file: str, stem: str) -> ModuleType:
    return _load(os.path.relpath(_checks_path(koan_file, stem)), "c")


def _quiet(_loop: asyncio.AbstractEventLoop, _context: dict[str, object]) -> None:
    pass


async def _drain(loop: asyncio.AbstractEventLoop) -> None:
    current = asyncio.current_task()
    leftovers = [task for task in asyncio.all_tasks(loop) if task is not current]
    for task in leftovers:
        task.cancel()
    if leftovers:
        await settle(asyncio.gather(*leftovers, return_exceptions=True))
    await settle(loop.create_task(loop.shutdown_asyncgens()))


# asyncio.run waits without bound for cancelled tasks, so a task that
# swallows cancellation would hang the run; this loop gives them settle's turns.
def _drive(coroutine: object) -> None:
    if not inspect.iscoroutine(coroutine):
        return
    loop = asyncio.new_event_loop()
    loop.set_exception_handler(_quiet)
    try:
        loop.run_until_complete(coroutine)
    finally:
        try:
            loop.run_until_complete(_drain(loop))
        finally:
            loop.close()


def _cause(koan_file: str, stem: str, case: Case) -> object:
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        try:
            _drive(case.run(load_review(koan_file, stem)))
        except AssertionError:
            return None
        except SystemExit:
            return "exited"
        except (Exception, asyncio.CancelledError) as error:
            return f"raised {type(error).__name__}"
        finally:
            gc.collect()
    return _PASSED


def run_checks(koan_file: str, stem: str) -> None:
    __tracebackhide__ = True
    path = review_path(koan_file, f"{stem}.py")
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        try:
            load_review(koan_file, stem)
        except (Exception, SystemExit) as error:
            raise ReviewDidNotLoad(path, error) from None
    for case in load_checks(koan_file, stem).CASES:
        cause = _cause(koan_file, stem, case)
        if cause is not _PASSED:
            raise HiddenCase(case.label, case.kind, path, cause) from None
