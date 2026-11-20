import hashlib
import os
import sys
from pathlib import Path
from typing import Final, Literal

from review_koans.blank import Blank, __


class _Fine:
    __slots__ = ()

    def __repr__(self) -> str:
        return "FINE"


FINE: Final = _Fine()


class Verdict(Exception):
    pass


def _short(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()[:10]


def digest(file: str, answer: int | Literal["fine"]) -> str:
    return _short(f"{file}:{answer}".encode("utf-8"))


def review_path(koan_file: str, file: str) -> str:
    folder = os.path.relpath(Path(koan_file).parent, Path.cwd())
    return (Path(folder) / "review" / file).as_posix()


def _is_line(answer: object) -> bool:
    return isinstance(answer, int) and not isinstance(answer, bool) and answer > 0


def _changed(path: str, source_digest: str) -> bool:
    try:
        return _short(Path(path).read_bytes()) != source_digest
    except OSError:
        return True


def _wrong_line(path: str, source_digest: str) -> str:
    message = f"Not that line. Look again at {path}."
    if not _changed(path, source_digest):
        return message
    return (
        f"{message}\n{path} has changed since it was generated, so its line numbers may have moved: "
        f"git diff {path} shows how."
    )


def _refusal(file: str, answer: object, digests: str, path: str, source_digest: str) -> str | None:
    accepted = digests.split(",")
    fine = digest(file, "fine") in accepted
    if answer is not FINE and not _is_line(answer):
        return f"Write FINE, or a line number of {path} as an integer."
    if fine:
        return None if answer is FINE else f"Read {path} again: it is fine. Write FINE."
    if answer is FINE:
        return f"Not fine: {path} has a bug. Write the number of the line where it is."
    return None if digest(file, answer) in accepted else _wrong_line(path, source_digest)


def verdict(file: str, answer: object, digests: str, source_digest: str) -> None:
    path = review_path(sys._getframe(1).f_code.co_filename, file)
    if answer is __:
        raise Blank("verdict", path)
    refusal = _refusal(file, answer, digests, path, source_digest)
    if refusal is not None:
        raise Verdict(refusal)
