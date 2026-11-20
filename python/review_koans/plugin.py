import inspect
import os
import re
from collections.abc import Generator
from dataclasses import dataclass
from pathlib import Path

import pytest

from review_koans import footer
from review_koans.offline import no_network

__all__ = ["no_network"]

_KOAN_FILE = re.compile(r"^\d\d_.*_test\.py$")
_PACKAGE = __name__.rpartition(".")[0]


@dataclass(frozen=True)
class _Finished:
    kind: str
    path: str
    line: int


@dataclass(frozen=True)
class _Failed:
    finished: _Finished
    failure: footer.Failure


class _Run:
    def __init__(self) -> None:
        self.folder: Path | None = None
        self.finished: list[_Finished] = []
        self.failures: list[_Failed] = []
        self.collection_errors: list[_Finished] = []

    @property
    def passed(self) -> int:
        return sum(1 for done in self.finished if done.kind == "ok")


_run_key = pytest.StashKey[_Run]()


def _verify() -> bool:
    return os.environ.get("KOANS_VERIFY") == "1"


def _is_koan(item: pytest.Item) -> bool:
    return isinstance(item, pytest.Function) and bool(_KOAN_FILE.match(item.path.name))


def _relative(item: pytest.Item, path: Path) -> str:
    return Path(os.path.relpath(path, item.config.invocation_params.dir)).as_posix()


def _is_own(error: BaseException) -> bool:
    return type(error).__module__.startswith(f"{_PACKAGE}.")


def _kind(error: BaseException) -> str:
    name = type(error).__name__
    if name == "HiddenCase" and _is_own(error):
        return f"HiddenCase:{getattr(error, 'kind', '')}"
    return name


def _write(error: BaseException) -> str | None:
    if type(error).__name__ == "Blank":
        return None
    review_path = getattr(error, "review_path", None)
    return review_path if isinstance(review_path, str) else None


def _failure_line(item: pytest.Function, excinfo: pytest.ExceptionInfo[BaseException]) -> int:
    in_koan = [entry for entry in excinfo.traceback if entry.path == item.path]
    return (in_koan[-1].lineno if in_koan else item.location[1]) + 1


def _record_failure(
    run: _Run, item: pytest.Function, report: pytest.TestReport, excinfo: pytest.ExceptionInfo[BaseException]
) -> None:
    error = excinfo.value
    own = _is_own(error)
    message = str(error) if own else excinfo.exconly()
    if own:
        report.longrepr = message
    path = _relative(item, item.path)
    finished = _Finished(_kind(error), path, item.location[1] + 1)
    failure = footer.Failure(
        path=path,
        line=_failure_line(item, excinfo),
        meditation=inspect.cleandoc(item.function.__doc__ or ""),
        message=message,
        write=_write(error),
    )
    run.finished.append(finished)
    run.failures.append(_Failed(finished, failure))


def pytest_configure(config: pytest.Config) -> None:
    config.stash[_run_key] = _Run()
    if _verify():
        config.option.maxfail = 0


def pytest_collection_finish(session: pytest.Session) -> None:
    koans = [item for item in session.items if _is_koan(item)]
    if koans:
        session.config.stash[_run_key].folder = koans[0].path.parent


@pytest.hookimpl(wrapper=True)
def pytest_runtest_makereport(
    item: pytest.Item, call: pytest.CallInfo[None]
) -> Generator[None, pytest.TestReport, pytest.TestReport]:
    report = yield
    if not _is_koan(item) or not isinstance(item, pytest.Function):
        return report
    run = item.config.stash[_run_key]
    if report.failed and call.excinfo is not None and call.when in ("setup", "call"):
        _record_failure(run, item, report, call.excinfo)
    elif call.when == "call" and report.passed:
        run.finished.append(_Finished("ok", _relative(item, item.path), item.location[1] + 1))
    return report


def _collection_error_line(path: Path, longrepr: str) -> int:
    try:
        compile(path.read_bytes(), str(path), "exec")
    except SyntaxError as error:
        return error.lineno or 0
    except OSError:
        return 0
    lines = re.findall(rf"^\S*{re.escape(path.name)}:(\d+): in ", longrepr, re.MULTILINE)
    return int(lines[-1]) if lines else 0


@pytest.hookimpl(wrapper=True)
def pytest_make_collect_report(
    collector: pytest.Collector,
) -> Generator[None, pytest.CollectReport, pytest.CollectReport]:
    report = yield
    path = collector.path
    if report.failed and isinstance(collector, pytest.Module) and _KOAN_FILE.match(path.name):
        relative = Path(os.path.relpath(path, collector.config.invocation_params.dir)).as_posix()
        line = _collection_error_line(path, str(report.longrepr))
        error = _Finished("CollectionError", relative, line)
        collector.config.stash[_run_key].collection_errors.append(error)
    return report


def _earliest(run: _Run) -> _Failed | None:
    if not run.failures:
        return None
    return min(run.failures, key=lambda failed: (failed.finished.path, failed.finished.line))


def pytest_terminal_summary(terminalreporter: pytest.TerminalReporter, config: pytest.Config) -> None:
    run = config.stash[_run_key]
    earliest = _earliest(run)
    if run.folder is not None:
        _write_footer(terminalreporter, run, run.folder, earliest)
    if _verify() and (run.folder is not None or run.collection_errors):
        _write_verify_lines(terminalreporter, run, earliest)


def _write_footer(
    terminalreporter: pytest.TerminalReporter, run: _Run, folder: Path, earliest: _Failed | None
) -> None:
    text = footer.render(
        run.passed, footer.total(folder), len(run.finished), earliest.failure if earliest else None
    )
    if text:
        terminalreporter.write_line("")
        for line in text.split("\n"):
            terminalreporter.write_line(line)


def _result_line(run: _Run, earliest: _Failed | None) -> str:
    if run.collection_errors:
        first = min(run.collection_errors, key=lambda error: (error.path, error.line))
        return f"KOANS-RESULT {first.kind} {first.path}:{first.line}"
    if earliest is None:
        return "KOANS-RESULT ok"
    return f"KOANS-RESULT {earliest.finished.kind} {earliest.failure.path}:{earliest.failure.line}"


def _write_verify_lines(
    terminalreporter: pytest.TerminalReporter, run: _Run, earliest: _Failed | None
) -> None:
    for done in sorted(run.finished, key=lambda done: (done.path, done.line)):
        terminalreporter.write_line(f"KOANS-TEST {done.kind} {done.path}:{done.line}")
    terminalreporter.write_line(_result_line(run, earliest))
