import re
from dataclasses import dataclass
from pathlib import Path

_WIDTH = 80
_KOAN_DEF = re.compile(r"^def test_", re.MULTILINE)


@dataclass(frozen=True)
class Failure:
    path: str
    line: int
    meditation: str
    message: str
    write: str | None


def separator(title: str) -> str:
    padded = f" {title} "
    fill = _WIDTH - len(padded)
    left = fill // 2
    return "-" * left + padded + "-" * (fill - left)


def _where(failure: Failure) -> str:
    if failure.write is None:
        return f"Meditate on {failure.path}:{failure.line}"
    return f"Write:        {failure.write}\nExercised by: {failure.path}:{failure.line}"


def _failed(passed: int, total: int, failure: Failure) -> str:
    meditation = "\n".join(f"    {line}" for line in failure.meditation.split("\n"))
    return (
        f"{failure.message}\n{separator('The master says')}\n{_where(failure)}\n"
        f"{meditation}\n{passed} of {total} koans answered."
    )


def render(passed: int, total: int, ran: int, failure: Failure | None) -> str:
    if failure is not None:
        return _failed(passed, total, failure)
    if ran == 0:
        return ""
    if ran >= total and passed == total:
        return f"{separator('Enlightenment')}\nAll {total} koans pass. Start again with: git checkout -- koans/"
    return f"{passed} of {total} koans answered. Run the whole suite for the rest."


def total(folder: Path) -> int:
    return sum(
        len(_KOAN_DEF.findall(path.read_text(encoding="utf-8")))
        for path in folder.glob("[0-9][0-9]_*_test.py")
    )
