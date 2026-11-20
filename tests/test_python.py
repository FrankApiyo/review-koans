"""The eleven self-tests for the Python track. REVIEW_KOANS_CHAPTER=NN narrows them to one chapter."""

import ast
import hashlib
import io
import re
import subprocess
import sys
import tokenize
import tomllib
import warnings
from collections import Counter
from dataclasses import dataclass
from pathlib import Path

import pytest

import traces
from dialects import PYTHON
from elixir_runner import KoansResult
from generate import blanks, render_review_with, render_test_variant
from harness import (
    ROOT,
    case_id,
    chapter_filter,
    enclosing_koan,
    files_under,
    fix_koan_line,
    has_fix,
    in_scope,
    koan_body,
    koan_lines,
    meditation,
    rendered_verdicts,
    review_renders,
    static_hits,
    tree_test_files,
    verdict_calls,
)
from python_runner import PYTHON_DIR as TRACK_DIR
from python_runner import PytestRun, koans_result, run_pytest, stage_each

TRACK = "python"
TREES = ("koans", "solutions")
SOURCE = TRACK_DIR / "source"
ALLOWLIST = ROOT / "tests" / "allowlist.txt"
COURSE_FILES = files_under(TRACK_DIR, ("source", "checks", "traces"), (".py",))
NETWORK = re.compile(
    r"\b(import|from)\s+(socket|ssl|urllib|http|requests|httpx|aiohttp)\b|open_connection|create_connection"
    r"|urlopen|subprocess\.(run|Popen|call|check_call|check_output)\("
)
REAL_CLOCK = re.compile(
    r"\btime\.(time|sleep|monotonic|perf_counter|process_time)\b|\b(datetime|date)\.(now|utcnow|today)\("
    r"|\.now\(|asyncio\.sleep\((?!0\))|\bwait_for\(|asyncio\.timeout\b|call_later|call_at|\.time\(\)"
)
PERSONAL = ("/" + "Users/", "/" + "home/")
VERDICT_ENDING = "Write FINE, or the line number of the bug."
FIX_MEDITATION = "Fix the bug in koans/review/{file} in place. The hidden checks name what still fails."
BLANK = re.compile(r"(?<!\w)__(?!\w)")
RUN_CHECKS = re.compile(r'run_checks\(__file__,\s*"(?P<stem>[^"]+)"\)')
IMPORTS_PYTEST = re.compile(r"^\s*(?:import|from)\s+pytest\b", re.M)
HIDDEN = "HiddenCase:"
COMPILE_ALL = (
    "import sys\n"
    "for path in sys.argv[1:]:\n"
    "    with open(path, 'rb') as source:\n"
    "        compile(source.read(), path, 'exec')\n"
)

REVIEWS = review_renders(TRACK)
VERDICTS = verdict_calls(TRACK)


def shown(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def tree_text(tree: str, name: str) -> str:
    return (TRACK_DIR / tree / name).read_text(encoding="utf-8")


def tree_reviews(tree: str) -> dict[str, str]:
    return {path.name: path.read_text(encoding="utf-8") for path in sorted((TRACK_DIR / tree / "review").glob("*.py"))}


def lines_of(text: str) -> list[int]:
    return koan_lines(text, PYTHON)


def verdict_for(file: str):
    [call] = [call for call in VERDICTS if call.file == file]
    return call


def whole_tree(tree: str) -> PytestRun:
    paths = [f"{tree}/{path.name}" for path in tree_test_files(TRACK, tree)] if chapter_filter() else [tree]
    return run_pytest(paths, verify=True)


def kinds_through(run: PytestRun, path: str, text: str, koan: int) -> dict[int, str | None]:
    return {line: run.results.get((path, line)) for line in lines_of(text) if line <= koan}


def earlier_are_ok(kinds: dict[int, str | None], koan: int) -> bool:
    return all(kind == "ok" for line, kind in kinds.items() if line < koan)


def first_blank_line(text: str) -> int:
    first = lines_of(text)[0]
    return next(n for n, line in enumerate(text.splitlines(), 1) if n > first and BLANK.search(line))


@pytest.fixture(scope="module")
def solutions_run() -> PytestRun:
    return whole_tree("solutions")


@pytest.fixture(scope="module")
def koans_run() -> PytestRun:
    return whole_tree("koans")


# 1. Every solution passes.


def test_solutions_reach_enlightenment(solutions_run):
    total = sum(len(lines_of(p.read_text(encoding="utf-8"))) for p in (TRACK_DIR / "solutions").glob("*_test.py"))
    ran = sum(len(lines_of(p.read_text(encoding="utf-8"))) for p in tree_test_files(TRACK, "solutions"))
    footer = f"All {total} koans pass." if ran == total else f"{ran} of {total} koans answered. Run the whole suite for the rest."
    assert solutions_run.returncode == 0, solutions_run.output[-3000:]
    assert footer in solutions_run.output
    assert list(solutions_run.results.values()) == ["ok"] * ran


# 2. Every unsolved koan fails as a blank or a hidden case.


def test_unsolved_koans_fail_as_blank_or_hidden_case(koans_run):
    expected = {}
    for path in tree_test_files(TRACK, "koans"):
        text, test_path = path.read_text(encoding="utf-8"), f"koans/{path.name}"
        fixes = {fix_koan_line(text, c.line, PYTHON) for c in VERDICTS if c.test_path == test_path and c.answer != "fine"}
        for line in lines_of(text):
            expected[(test_path, line)] = f"{HIDDEN}exploit" if line in fixes else "Blank"
    assert koans_run.returncode != 0
    assert koans_run.results == expected, koans_run.output[-3000:]


# 3. Every blank and every fix block fails alone.


@dataclass(frozen=True)
class BlankVariant:
    id: str
    key: str
    name: str
    text: str
    line: int

    @property
    def staged(self) -> str:
        return f"_variants/batch/{self.key}/{self.name}"


def blank_variants() -> list[BlankVariant]:
    variants = []
    for path in sorted(SOURCE.glob(PYTHON.test_glob)):
        if not in_scope(path.name):
            continue
        text = path.read_text(encoding="utf-8")
        for blank in blanks(shown(path), text, PYTHON):
            key = f"v{len(variants) + 1:04d}"
            variant, line = render_test_variant(shown(path), text, PYTHON, REVIEWS, blank.index)
            variants.append(BlankVariant(case_id(path.name, f"n{blank.index}"), key, path.name, variant, line))
    return variants


BLANK_VARIANTS = blank_variants()


@pytest.fixture(scope="module")
def batch_run() -> PytestRun:
    reviews = tree_reviews("solutions")
    folder = stage_each("batch", {v.key: ({v.name: v.text}, reviews) for v in BLANK_VARIANTS})
    return run_pytest([folder], verify=True)


@pytest.mark.parametrize("variant", BLANK_VARIANTS, ids=lambda v: v.id)
def test_each_blank_fails_alone(variant, batch_run):
    lines = variant.text.splitlines()
    koans_part = "\n".join(lines[lines_of(variant.text)[0] - 1 :])
    assert len(BLANK.findall(koans_part)) == 1 and BLANK.search(lines[variant.line - 1]), "one blank, on its line"
    koan = enclosing_koan(variant.text, variant.line, PYTHON)
    kinds = kinds_through(batch_run, variant.staged, variant.text, koan)
    assert kinds[koan] == "Blank", batch_run.output[-3000:]
    assert earlier_are_ok(kinds, koan), kinds


def test_first_blank_fails_on_its_own_line(koans_run):
    files = tree_test_files(TRACK, "koans")
    if not files:
        pytest.skip("no koan files in scope")
    first = files[0]
    line = first_blank_line(first.read_text(encoding="utf-8"))
    assert koans_result(koans_run) == KoansResult("Blank", f"koans/{first.name}", line), koans_run.output[-3000:]


@dataclass(frozen=True)
class ReviewVariant:
    id: str
    file: str
    block: int
    half: int | None
    tag: str | None


def review_variants(select) -> list[ReviewVariant]:
    found = []
    for file, review in REVIEWS.items():
        if not in_scope(file):
            continue
        for k, block in enumerate(review.blocks):
            if block.kind == "fix" and select(block.kind, None):
                found.append(ReviewVariant(case_id(file, f"b{k}"), file, k, None, None))
            for j, half in enumerate(block.halves):
                if select(block.kind, half):
                    mark = "a" if half.kind == "alt" else "w"
                    found.append(ReviewVariant(case_id(file, f"b{k}", f"{mark}{j}"), file, k, j, half.tag))
    return found


FIX_BLOCKS = review_variants(lambda kind, half: kind == "fix" and half is None)
WRONG_HALVES = review_variants(lambda kind, half: kind == "fix" and half is not None and half.kind == "wrong")
ALT_HALVES = review_variants(lambda kind, half: half is not None and half.kind == "alt")
GUARD_MUTANTS = review_variants(lambda kind, half: kind == "guard" and half is not None and half.kind == "wrong")
ALL_REVIEW_VARIANTS = [*FIX_BLOCKS, *WRONG_HALVES, *ALT_HALVES, *GUARD_MUTANTS]
REVIEW_KEYS = {case.id: f"v{number:04d}" for number, case in enumerate(ALL_REVIEW_VARIANTS, 1)}


def review_text(case: ReviewVariant) -> str:
    source = SOURCE / "review" / case.file
    return render_review_with(shown(source), source.read_text(encoding="utf-8"), PYTHON, case.block, case.half)


def staged_test_name(case: ReviewVariant) -> str:
    return Path(verdict_for(case.file).test_path).name


@pytest.fixture(scope="module")
def review_run() -> PytestRun:
    """One pytest run over every review variant: the solutions with one review block swapped, per folder."""
    reviews = tree_reviews("solutions")
    staged = {}
    for case in ALL_REVIEW_VARIANTS:
        name = staged_test_name(case)
        staged[REVIEW_KEYS[case.id]] = ({name: tree_text("solutions", name)}, {**reviews, case.file: review_text(case)})
    return run_pytest([stage_each("review", staged)], verify=True)


def review_kinds(case: ReviewVariant, run: PytestRun) -> tuple[dict[int, str | None], int]:
    """The kinds up to the koan that runs the review's checks, from the shared review run."""
    assert review_text(case) != tree_text("solutions", f"review/{case.file}"), "the variant changes the solved review"
    call = verdict_for(case.file)
    name = staged_test_name(case)
    text = tree_text("solutions", name)
    [answered] = [v for v in rendered_verdicts(text) if v.file == case.file]
    if call.answer == "fine":
        koan = enclosing_koan(text, answered.line, PYTHON)
    else:
        koan = fix_koan_line(text, answered.line, PYTHON)
    return kinds_through(run, f"_variants/review/{REVIEW_KEYS[case.id]}/{name}", text, koan), koan


@pytest.mark.parametrize("case", FIX_BLOCKS, ids=lambda c: c.id)
def test_each_fix_block_fails_alone(case, review_run):
    kinds, koan = review_kinds(case, review_run)
    assert (kinds[koan] or "").startswith(HIDDEN), review_run.output[-3000:]
    assert earlier_are_ok(kinds, koan), kinds


# 4. Every wrong half fails as a hidden case; every alternative passes.


@pytest.mark.parametrize("case", WRONG_HALVES, ids=lambda c: c.id)
def test_each_wrong_half_fails_as_hidden_case(case, review_run):
    kinds, koan = review_kinds(case, review_run)
    expected = f"{HIDDEN}twin" if case.tag == "refuses" else HIDDEN
    assert (kinds[koan] or "").startswith(expected), (kinds, review_run.output[-3000:])
    assert earlier_are_ok(kinds, koan), kinds


@pytest.mark.parametrize("case", ALT_HALVES, ids=lambda c: c.id)
def test_each_alt_half_passes(case, review_run):
    kinds, _koan = review_kinds(case, review_run)
    assert set(kinds.values()) == {"ok"}, (kinds, review_run.output[-3000:])


@pytest.mark.parametrize("case", GUARD_MUTANTS, ids=lambda c: c.id)
def test_each_guard_mutant_fails_as_hidden_case(case, review_run):
    kinds, koan = review_kinds(case, review_run)
    assert (kinds[koan] or "").startswith(HIDDEN), (kinds, review_run.output[-3000:])
    assert earlier_are_ok(kinds, koan), kinds


# 5. Verdicts are consistent.


def digest(file: str, answer: int | str) -> str:
    return hashlib.sha256(f"{file}:{answer}".encode("utf-8")).hexdigest()[:10]


@pytest.mark.parametrize("call", VERDICTS, ids=lambda c: case_id(c.file))
def test_verdicts_are_consistent(call):
    review = REVIEWS[call.file]
    [rendered] = [v for v in rendered_verdicts(tree_text("koans", Path(call.test_path).name)) if v.line == call.line]
    accepted = {digest(call.file, line) for line in review.accepted} or {digest(call.file, "fine")}
    koans_review = tree_text("koans", f"review/{call.file}")
    assert (call.answer == "fine") == (not has_fix(review))
    assert rendered.answer == PYTHON.value_blank
    assert rendered.digests == ",".join(sorted(accepted))
    assert rendered.source_digest == hashlib.sha256(koans_review.encode("utf-8")).hexdigest()[:10]
    if has_fix(review):
        assert call.answer in review.accepted
        assert digest(call.file, "fine") not in accepted
    lines = range(0, len(review.koans.splitlines()) + 6)
    assert [n for n in lines if n not in review.accepted and digest(call.file, n) in accepted] == []


def test_fine_share_is_between_15_and_25_percent():
    if chapter_filter():
        pytest.skip("the share is a whole-track property")
    fine = sum(1 for review in REVIEWS.values() if not has_fix(review))
    assert 0.15 <= fine / len(REVIEWS) <= 0.25, f"{fine} of {len(REVIEWS)} reviews are fine"


# 6 and 7. Generated files and traces are current.


def run_tool(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run([sys.executable, *args], cwd=ROOT, capture_output=True, text=True, timeout=600)


TRACE_FILES = [p for p in sorted((TRACK_DIR / "traces").glob("*.trace")) if in_scope(p.name)]


def test_generated_files_are_current():
    done = run_tool("tools/generate.py", "--check", TRACK)
    assert done.returncode == 0, done.stdout + done.stderr


def test_traces_are_current():
    names = [path.name.removesuffix(".trace") for path in TRACE_FILES] if chapter_filter() else []
    done = run_tool("tools/traces.py", "check", TRACK, *names)
    assert done.returncode == 0, done.stdout + done.stderr


@pytest.mark.parametrize("path", TRACE_FILES, ids=lambda p: case_id(p.name))
def test_traces_hold_no_warnings_or_personal_paths(path):
    text = path.read_text(encoding="utf-8")
    assert traces.refusal(text) is None
    assert [needle for needle in PERSONAL if needle in text] == []


# 8. Everything compiles and loads without warnings.

COMPILED = files_under(TRACK_DIR, ("koans", "solutions", "checks", "traces", "review_koans"), (".py",))


def test_trees_compile_without_warnings():
    # compile() rather than py_compile, so no .pyc lands in koans/.
    done = subprocess.run(
        [sys.executable, "-W", "error", "-c", COMPILE_ALL, *map(str, COMPILED)],
        capture_output=True,
        text=True,
        timeout=600,
    )
    assert COMPILED
    assert done.returncode == 0, done.stdout + done.stderr


def test_test_files_load_without_warnings(solutions_run, koans_run):
    for run in (solutions_run, koans_run):
        assert "warnings summary" not in run.output, run.output
        assert "Warning:" not in run.output, run.output


def _exits_finally(node: ast.AST, in_loop: bool = False) -> list[int]:
    """Lines of return, break or continue that would leave a finally block."""
    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.Lambda, ast.ClassDef)):
        return []
    if isinstance(node, ast.Return) or (isinstance(node, (ast.Break, ast.Continue)) and not in_loop):
        return [node.lineno]
    loop = in_loop or isinstance(node, (ast.For, ast.AsyncFor, ast.While))
    return [line for child in ast.iter_child_nodes(node) for line in _exits_finally(child, loop)]


def finally_exits(text: str) -> list[int]:
    with warnings.catch_warnings():
        warnings.simplefilter("ignore", SyntaxWarning)
        tree = ast.parse(text)
    return sorted(
        line
        for node in ast.walk(tree)
        if isinstance(node, (ast.Try, ast.TryStar))
        for statement in node.finalbody
        for line in _exits_finally(statement)
    )


def test_finally_exits_are_found():
    leaves = "def f():\n    try:\n        pass\n    finally:\n        return 1\n"
    loops = "for x in y:\n    try:\n        pass\n    finally:\n        for z in x:\n            break\n        continue\n"
    nested = "try:\n    pass\nfinally:\n    def g():\n        return 2\n"
    assert (finally_exits(leaves), finally_exits(loops), finally_exits(nested)) == ([5], [7], [])


def finally_sources() -> dict[str, str]:
    """Every file of the track as Python parses it; source/ reviews hold markers, so their renders stand in."""
    found = {shown(path): path.read_text(encoding="utf-8") for path in COMPILED}
    found.update({f"{case.file} {case.id}": review_text(case) for case in ALL_REVIEW_VARIANTS})
    return found


def test_no_return_break_or_continue_in_finally():
    hits = {name: lines for name, text in finally_sources().items() if (lines := finally_exits(text))}
    assert hits == {}


# 9 and 10. No network and no real clock in course code.


def test_no_network_in_course_code():
    assert static_hits(COURSE_FILES, NETWORK) == []


def test_offline_guard_is_active():
    run = run_pytest(["-rA", "verify/offline_test.py"])
    passed = sorted(re.findall(r"^PASSED verify/offline_test\.py::(\w+)$", run.output, re.M))
    assert run.returncode == 0, run.output[-3000:]
    assert passed == ["test_a_tcp_connect_is_refused_inside_a_koan", "test_asyncio_run_still_works"]


def test_no_real_clock_in_course_code():
    assert static_hits(COURSE_FILES, REAL_CLOCK, ALLOWLIST) == []


# 11. Hygiene.


def tree_files(tree: str) -> list[str]:
    base = TRACK_DIR / tree
    return sorted(
        p.relative_to(base).as_posix()
        for p in base.rglob("*")
        if p.is_file() and not any(part.startswith((".", "__pycache__")) for part in p.relative_to(base).parts)
    )


def meditations(text: str) -> list[str | None]:
    return [meditation(text, line, PYTHON) for line in lines_of(text)]


def test_trees_mirror_each_other(koans_run, solutions_run):
    assert tree_files("koans") == tree_files("solutions")
    for path in tree_test_files(TRACK, "koans"):
        assert meditations(path.read_text(encoding="utf-8")) == meditations(tree_text("solutions", path.name))

    def per_file(run: PytestRun) -> Counter[str]:
        return Counter(Path(path).name for path, _line in run.results)

    assert per_file(koans_run) == per_file(solutions_run)


@pytest.mark.parametrize("tree", TREES)
def test_every_koan_has_a_meditation(tree):
    missing = []
    for path in tree_test_files(TRACK, tree):
        text = path.read_text(encoding="utf-8")
        missing.extend(
            f"{tree}/{path.name}:{line}"
            for line, said in zip(lines_of(text), meditations(text))
            if not (said or "").strip()
        )
    assert missing == []


def test_native_runtime_suite_passes():
    run = run_pytest(["verify"])
    assert run.returncode == 0, run.output[-3000:]


CHECKS_FILES = [p for p in sorted((TRACK_DIR / "checks").glob("*_checks.py")) if in_scope(p.name)]


def cases_text(path: Path) -> str:
    text = path.read_text(encoding="utf-8")
    start = text.find("CASES = [")
    assert start > -1, f"{path.name} defines CASES"
    return text[start:]


@pytest.mark.parametrize("path", CHECKS_FILES, ids=lambda p: case_id(p.name))
def test_checks_have_twin_and_exploit(path):
    text = cases_text(path)
    assert 'twin("' in text and 'exploit("' in text


@pytest.mark.parametrize("path", CHECKS_FILES, ids=lambda p: case_id(p.name))
def test_checks_list_twins_before_exploits(path):
    text = cases_text(path)
    assert -1 < text.rfind('twin("') < text.find('exploit("'), "a fix that refuses everything must fail as twin"


@pytest.mark.parametrize("path", CHECKS_FILES, ids=lambda p: case_id(p.name))
def test_checks_never_import_pytest(path):
    assert IMPORTS_PYTEST.findall(path.read_text(encoding="utf-8")) == []


@pytest.mark.parametrize("call", VERDICTS, ids=lambda c: case_id(c.file))
def test_fix_koan_follows_its_verdict(call):
    text = tree_text("koans", Path(call.test_path).name)
    if call.answer == "fine":
        koan = enclosing_koan(text, call.line, PYTHON)
    else:
        koan = fix_koan_line(text, call.line, PYTHON)
    stem = Path(call.file).stem
    assert [m["stem"] for m in RUN_CHECKS.finditer(koan_body(text, koan, PYTHON))] == [stem]
    assert (TRACK_DIR / "checks" / f"{stem}_checks.py").is_file()


@pytest.mark.parametrize("call", VERDICTS, ids=lambda c: case_id(c.file))
def test_review_meditations_use_the_frozen_wording(call):
    text = tree_text("koans", Path(call.test_path).name)
    assert (meditation(text, enclosing_koan(text, call.line, PYTHON), PYTHON) or "").endswith(VERDICT_ENDING)
    if call.answer != "fine":
        fix_koan = fix_koan_line(text, call.line, PYTHON)
        assert meditation(text, fix_koan, PYTHON) == FIX_MEDITATION.format(file=call.file)


def test_learner_commands_are_frozen():
    project = tomllib.loads((TRACK_DIR / "pyproject.toml").read_text(encoding="utf-8"))
    options = project["tool"]["pytest"]["ini_options"]
    assert "pytest==9.2.0" in project["project"]["dependencies"]
    assert "-x" in options["addopts"].split()
    assert options["testpaths"] == ["koans"]


REVIEW_FILES = [p for p in sorted((TRACK_DIR / "koans" / "review").glob("*.py")) if in_scope(p.name)]


def comment_lines(text: str) -> list[int]:
    tokens = tokenize.generate_tokens(io.StringIO(text).readline)
    return [token.start[0] for token in tokens if token.type == tokenize.COMMENT]


@pytest.mark.parametrize("path", REVIEW_FILES, ids=lambda p: case_id(p.name))
def test_review_files_have_no_hint_comments(path):
    assert comment_lines(path.read_text(encoding="utf-8")) == [], "a comment survives into the learner's file"
