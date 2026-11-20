import re
from pathlib import Path

HEADER = re.compile(r"Traceback \(most recent call last\):$")
COURSE_FRAME = re.compile(r'^[ |+-]*File "(traces/[^"]+)", line (\d+)')
EXCEPTION_LINE = re.compile(r"^(?: *\| ?)?(?P<name>[A-Za-z_][\w.]*)(?:: .*)?$")


def read(name: str) -> str:
    return Path("traces", f"{name}.py.trace").read_text(encoding="utf-8")


def exceptions(name: str) -> list[str]:
    names: list[str] = []
    in_traceback = False
    for line in read(name).splitlines():
        if HEADER.search(line):
            in_traceback = True
        elif in_traceback and (found := EXCEPTION_LINE.match(line)):
            names.append(found["name"])
            in_traceback = False
    return names


def exception(name: str) -> str | None:
    found = exceptions(name)
    return found[-1] if found else None


def _course_frames(lines: list[str]) -> list[tuple[str, int]]:
    matches = (COURSE_FRAME.match(line) for line in lines)
    return [(found[1], int(found[2])) for found in matches if found]


def frames(name: str) -> list[tuple[str, int]]:
    return _course_frames(read(name).splitlines())


def crash_frame(name: str) -> tuple[str, int] | None:
    lines = read(name).splitlines()
    starts = [i for i, line in enumerate(lines) if HEADER.search(line)]
    last_block = lines[starts[-1]:] if starts else []
    course = _course_frames(last_block)
    return course[-1] if course else None
