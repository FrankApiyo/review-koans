"""The self-tests for the TypeScript track. REVIEW_KOANS_CHAPTER=NN narrows them to one chapter.

A chapter filter skips the runtime suite (`npm run verify`), which no chapter changes: a change to
typescript/support/ or typescript/verify/ must run this file unfiltered.
"""

import json
import re
import subprocess
import sys
from collections import Counter
from dataclasses import dataclass
from pathlib import Path

import pytest

import traces
from dialects import TYPESCRIPT
from elixir_runner import KoansResult
from generate import blanks, render_review_with, render_test_variant
from harness import (
    PERSONAL,
    ROOT,
    ReviewVariant,
    case_id,
    chapter_filter,
    earlier_are_ok,
    enclosing_koan,
    files_under,
    fix_koan_line,
    has_fix,
    in_scope,
    kinds_through,
    koan_body,
    koan_lines,
    meditation,
    meditations,
    personal_path_hits,
    rendered_verdicts,
    review_renders,
    review_variants,
    static_hits,
    tracked_files,
    tree_files,
    tree_test_files,
    verdict_calls,
    verdict_problems,
)
from typescript_runner import TS_DIR as TRACK_DIR
from typescript_runner import TSC, VITEST, VitestRun, koans_result, run_in_track, run_staged, run_vitest, syntax_of

if not VITEST.exists():
    pytest.fail("run: cd typescript && npm ci", pytrace=False)

TRACK = "typescript"
TREES = ("koans", "solutions")
SOURCE = TRACK_DIR / "source"
ALLOWLIST = ROOT / "tests" / "allowlist.txt"
COURSE_FILES = files_under(TRACK_DIR, ("source", "checks", "traces"), (".ts",))
OTHER_ZONE = {"TZ": "Pacific/Auckland", "LANG": "de_DE.UTF-8", "LC_ALL": "de_DE.UTF-8"}
NETWORK = re.compile(
    r"""["'](?:node:)?(net|tls|http|https|http2|dgram|dns|child_process|worker_threads|cluster)["']"""
    r"""|\bfetch\(|\bWebSocket\b|XMLHttpRequest|\brequire\("""
)
REAL_CLOCK = re.compile(
    r"""\bDate\.now\(|new Date\(\s*\)|\bnew Date\b(?!\s*\()|(?<![\w.$])Date\(\s*\)|performance\.now|process\.hrtime"""
    r"""|\bIntl\b|toLocale\w*\(|process\.nextTick|setTimeout|setInterval|setImmediate|useRealTimers"""
    r"""|\bAbortSignal\.timeout\b|["'](?:node:)?timers(?:/promises)?["']|\blocaleCompare\((?![^()\n]*,\s*["'])"""
)
VERDICT_MEDITATION = 'Read koans/review/{file}. Write "fine", or the line number of the bug.'
FIX_MEDITATION = "Fix the bug in koans/review/{file} in place. The hidden checks name what still fails."
BLANK = re.compile(r"(?<![\w$])__(?:blank\(\))?(?![\w$])")
RUN_CHECKS = re.compile(r'runChecks\(import\.meta\.url,\s*"(?P<stem>[^"]+)"\)')
IMPORTS_VITEST = re.compile(r"""(?:\bfrom|\bimport)\s*\(?\s*["']vitest(?:/[^"']*)?["']""")
IMPORTS_REVIEW = re.compile(r"""(?:\bfrom|\bimport)\s*\(?\s*["'][^"']*\breview/""")
TO_BE = re.compile(r"\.toBe\(")
WARNINGS = re.compile(r"Warning|warning:")
HIDDEN = "HiddenCase:"
UNTRACKED = {"node_modules", "_variants"}

REVIEWS = review_renders(TRACK)
VERDICTS = verdict_calls(TRACK)


def shown(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def tree_text(tree: str, name: str) -> str:
    return (TRACK_DIR / tree / name).read_text(encoding="utf-8")


def tree_reviews(tree: str) -> dict[str, str]:
    return {path.name: path.read_text(encoding="utf-8") for path in sorted((TRACK_DIR / tree / "review").glob("*.ts"))}


def lines_of(text: str) -> list[int]:
    return koan_lines(text, TYPESCRIPT)


def verdict_for(file: str):
    [call] = [call for call in VERDICTS if call.file == file]
    return call


def koan_count(paths: list[Path]) -> int:
    return sum(len(lines_of(path.read_text(encoding="utf-8"))) for path in paths)


def whole_tree(tree: str, env: dict[str, str] | None = None) -> VitestRun:
    paths = [f"{tree}/{path.name}" for path in tree_test_files(TRACK, tree)] if chapter_filter() else []
    return run_vitest(paths, koans_dir=tree, verify=True, env=env or {})


def first_blank_line(text: str) -> int:
    first = lines_of(text)[0]
    return next(n for n, line in enumerate(text.splitlines(), 1) if n > first and BLANK.search(line))


@pytest.fixture(scope="module")
def solutions_run() -> VitestRun:
    return whole_tree("solutions")


@pytest.fixture(scope="module")
def koans_run() -> VitestRun:
    return whole_tree("koans")


# 1. Every solution passes, in any machine zone and locale.


def test_solutions_reach_enlightenment(solutions_run):
    total = koan_count(sorted((TRACK_DIR / "solutions").glob(TYPESCRIPT.test_glob)))
    ran = koan_count(tree_test_files(TRACK, "solutions"))
    footer = f"All {total} koans pass." if ran == total else f"{ran} of {total} koans answered. Run the whole suite for the rest."
    assert solutions_run.returncode == 0, solutions_run.output[-3000:]
    assert footer in solutions_run.output
    assert list(solutions_run.results.values()) == ["ok"] * ran


def test_solutions_pass_in_another_zone_and_locale(solutions_run):
    elsewhere = whole_tree("solutions", OTHER_ZONE)
    assert elsewhere.returncode == 0, elsewhere.output[-3000:]
    assert elsewhere.results == solutions_run.results


# 2. Every unsolved koan fails as a blank or a hidden case.


def test_unsolved_koans_fail_as_blank_or_hidden_case(koans_run):
    expected = {}
    for path in tree_test_files(TRACK, "koans"):
        text, test_path = path.read_text(encoding="utf-8"), f"koans/{path.name}"
        fixes = {fix_koan_line(text, c.line, TYPESCRIPT) for c in VERDICTS if c.test_path == test_path and c.answer != "fine"}
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
    for path in sorted(SOURCE.glob(TYPESCRIPT.test_glob)):
        if not in_scope(path.name):
            continue
        text = path.read_text(encoding="utf-8")
        for blank in blanks(shown(path), text, TYPESCRIPT):
            key = f"v{len(variants) + 1:04d}"
            variant, line = render_test_variant(shown(path), text, TYPESCRIPT, REVIEWS, blank.index)
            variants.append(BlankVariant(case_id(path.name, f"n{blank.index}"), key, path.name, variant, line))
    return variants


BLANK_VARIANTS = blank_variants()


@pytest.fixture(scope="module")
def batch_run() -> VitestRun:
    reviews = tree_reviews("solutions")
    return run_staged("batch", {v.key: ({v.name: v.text}, reviews) for v in BLANK_VARIANTS})


@pytest.mark.parametrize("variant", BLANK_VARIANTS, ids=lambda v: v.id)
def test_each_blank_fails_alone(variant, batch_run):
    lines = variant.text.splitlines()
    koans_part = "\n".join(lines[lines_of(variant.text)[0] - 1 :])
    assert len(BLANK.findall(koans_part)) == 1 and BLANK.search(lines[variant.line - 1]), "one blank, on its line"
    koan = enclosing_koan(variant.text, variant.line, TYPESCRIPT)
    kinds = kinds_through(batch_run, variant.staged, variant.text, koan, TYPESCRIPT)
    assert kinds[koan] == "Blank", batch_run.output[-3000:]
    assert earlier_are_ok(kinds, koan), kinds


def test_first_blank_fails_on_its_own_line(koans_run):
    files = tree_test_files(TRACK, "koans")
    if not files:
        pytest.skip("no koan files in scope")
    first = files[0]
    line = first_blank_line(first.read_text(encoding="utf-8"))
    assert koans_result(koans_run) == KoansResult("Blank", f"koans/{first.name}", line), koans_run.output[-3000:]


FIX_BLOCKS = review_variants(REVIEWS, lambda kind, half: kind == "fix" and half is None)
WRONG_HALVES = review_variants(REVIEWS, lambda kind, half: kind == "fix" and half is not None and half.kind == "wrong")
ALT_HALVES = review_variants(REVIEWS, lambda kind, half: half is not None and half.kind == "alt")
GUARD_MUTANTS = review_variants(REVIEWS, lambda kind, half: kind == "guard" and half is not None and half.kind == "wrong")
ALL_REVIEW_VARIANTS = [*FIX_BLOCKS, *WRONG_HALVES, *ALT_HALVES, *GUARD_MUTANTS]
REVIEW_KEYS = {case.id: f"v{number:04d}" for number, case in enumerate(ALL_REVIEW_VARIANTS, 1)}


def review_text(case: ReviewVariant) -> str:
    source = SOURCE / "review" / case.file
    return render_review_with(shown(source), source.read_text(encoding="utf-8"), TYPESCRIPT, case.block, case.half)


def staged_test_name(case: ReviewVariant) -> str:
    return Path(verdict_for(case.file).test_path).name


@pytest.fixture(scope="module")
def review_run() -> VitestRun:
    """One Vitest run over every review variant: the solutions with one review block swapped, per folder."""
    reviews = tree_reviews("solutions")
    staged = {}
    for case in ALL_REVIEW_VARIANTS:
        name = staged_test_name(case)
        staged[REVIEW_KEYS[case.id]] = ({name: tree_text("solutions", name)}, {**reviews, case.file: review_text(case)})
    return run_staged("review", staged)


def review_kinds(case: ReviewVariant, run: VitestRun) -> tuple[dict[int, str | None], int]:
    """The kinds up to the koan that runs the review's checks, from the shared review run."""
    assert review_text(case) != tree_text("solutions", f"review/{case.file}"), "the variant changes the solved review"
    call = verdict_for(case.file)
    name = staged_test_name(case)
    text = tree_text("solutions", name)
    [answered] = [v for v in rendered_verdicts(text) if v.file == case.file]
    if call.answer == "fine":
        koan = enclosing_koan(text, answered.line, TYPESCRIPT)
    else:
        koan = fix_koan_line(text, answered.line, TYPESCRIPT)
    return kinds_through(run, f"_variants/review/{REVIEW_KEYS[case.id]}/{name}", text, koan, TYPESCRIPT), koan


@pytest.mark.parametrize("case", FIX_BLOCKS, ids=lambda c: c.id)
def test_each_fix_block_fails_alone(case, review_run):
    kinds, koan = review_kinds(case, review_run)
    assert (kinds[koan] or "").startswith(HIDDEN), review_run.output[-3000:]
    assert earlier_are_ok(kinds, koan), kinds


# 4. Every wrong half fails as a hidden case; every alternative passes; no half repeats another.


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


def same_code(lines: tuple[str, ...]) -> str:
    return re.sub(r"\s+", "", "".join(lines))


IN_SCOPE_REVIEWS = [file for file in REVIEWS if in_scope(file)]


def test_halves_compare_without_whitespace():
    assert same_code(("  return a*b",)) == same_code(("return a * b", ""))


@pytest.mark.parametrize("file", IN_SCOPE_REVIEWS, ids=lambda f: case_id(f))
def test_no_half_repeats_the_block_or_another_half(file):
    repeats = []
    for k, block in enumerate(REVIEWS[file].blocks):
        seen = {same_code(block.buggy): "buggy", same_code(block.fixed): "fixed"}
        for j, half in enumerate(block.halves):
            code = same_code(half.lines)
            if code in seen:
                repeats.append(f"block {k} half {j} repeats {seen[code]}")
            seen.setdefault(code, f"half {j}")
    assert repeats == []


# 5. Verdicts are consistent.


@pytest.mark.parametrize("call", VERDICTS, ids=lambda c: case_id(c.file))
def test_verdicts_are_consistent(call):
    koans_test = tree_text("koans", Path(call.test_path).name)
    koans_review = tree_text("koans", f"review/{call.file}")
    assert verdict_problems(call, REVIEWS[call.file], koans_test, koans_review, TYPESCRIPT) == []


def test_fine_share_is_between_15_and_25_percent():
    if chapter_filter():
        pytest.skip("the share is a whole-track property")
    fine = sum(1 for review in REVIEWS.values() if not has_fix(review))
    assert 0.15 <= fine / len(REVIEWS) <= 0.25, f"{fine} of {len(REVIEWS)} reviews are fine"


# 6 and 7. Generated files and traces are current; no crash line carries a type.


def run_tool(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run([sys.executable, *args], cwd=ROOT, capture_output=True, text=True, timeout=600)


TRACE_FILES = [p for p in sorted((TRACK_DIR / "traces").glob("*.trace")) if in_scope(p.name)]
TRACE_FRAME = re.compile(r"^\s+at .*?(traces/[^\s:()]+):(\d+)", re.M)


def crash_frame(fixture: Path) -> tuple[str, int]:
    """The first course frame of the captured stack, as `trace.crashFrame` reads it."""
    stderr = fixture.read_text(encoding="utf-8").partition("--- stderr\n")[2]
    found = TRACE_FRAME.search(stderr)
    assert found, f"{fixture.name} names no course frame"
    return found[1], int(found[2])


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


@pytest.mark.parametrize("path", TRACE_FILES, ids=lambda p: case_id(p.name))
def test_trace_crash_lines_carry_no_type_annotations(path):
    program, line = crash_frame(path)
    source = TRACK_DIR / program
    [syntax] = syntax_of([source]).values()
    assert line not in syntax.types, f"{program}:{line}: {source.read_text(encoding='utf-8').splitlines()[line - 1]}"


# 8. Everything type-checks; runs print no warnings; the trees hold only sources.


def test_course_code_type_checks():
    done = run_in_track([str(TSC), "--noEmit", "-p", "tsconfig.json"], timeout=600)
    assert (done.returncode, done.stdout) == (0, "")


def test_runs_print_no_warnings(solutions_run, koans_run):
    for run in (solutions_run, koans_run):
        assert WARNINGS.findall(run.output) == [], run.output[-3000:]


@pytest.mark.parametrize("tree", TREES)
def test_no_build_output_in_trees(tree):
    found = tree_files(TRACK_DIR / tree)
    assert found
    assert [name for name in found if not name.endswith(".ts")] == []


# 9 and 10. No network, processes or real clock in course code.


def test_no_network_or_processes_in_course_code():
    assert static_hits(COURSE_FILES, NETWORK) == []


@pytest.fixture(scope="module")
def runtime_run() -> subprocess.CompletedProcess[str]:
    if chapter_filter():
        pytest.skip("the runtime suite is chapter-independent; run unfiltered after changing typescript/support/")
    return run_in_track(["npm", "run", "verify", "--", "--reporter=verbose"])


GUARD_FILES = {"guard_test.ts", "guard_install_test.ts"}


def test_offline_guard_is_active(runtime_run):
    passed = set(re.findall(r"^ +✓ verify/(\w+\.ts) > ", runtime_run.stdout, re.M))
    failed = set(re.findall(r"^ +[×✗] verify/(\w+\.ts) > ", runtime_run.stdout, re.M))
    assert GUARD_FILES <= passed, runtime_run.stdout[-3000:]
    assert GUARD_FILES & failed == set(), runtime_run.stdout[-3000:]


def test_no_real_clock_in_course_code():
    assert static_hits(COURSE_FILES, REAL_CLOCK, ALLOWLIST) == []


def test_clock_ban_catches_each_form():
    caught = [
        "Date.now()", "new Date()", "performance.now()", "process.hrtime.bigint()", "new Intl.DateTimeFormat()",
        "d.toLocaleDateString()", "process.nextTick(f)", "setTimeout(f, 0)", "setInterval(f, 1)", "setImmediate(f)",
        "vi.useRealTimers()", "AbortSignal.timeout(10)", 'import { setTimeout as wait } from "node:timers/promises"',
        "import timers from 'node:timers'", "a.localeCompare(b)", "names.sort((a, b) => a.localeCompare(b))",
        'n.sort((a, b) => a.localeCompare(b)).join(", ")', '[a.localeCompare(b), "z"]', "const d = new Date",
        "const s = Date()", 'import { scheduler } from "timers/promises"', "import { setTimeout } from 'timers'",
        'import { scheduler } from "node:timers/promises"',
    ]
    allowed = [
        'a.localeCompare(b, "en")', "new Date(\"2024-01-01T00:00:00Z\")", "new Date(2024, 0, 1)", "isDate(x)",
        "x.toDate()", 'import { stamp } from "./timers.ts"',
    ]
    assert [form for form in caught if not REAL_CLOCK.search(form)] == []
    assert [form for form in allowed if REAL_CLOCK.search(form)] == []


def test_network_ban_catches_each_form():
    caught = ['import net from "net"', "import http from 'http'", 'import { spawn } from "child_process"',
              'import tls from "node:tls"', "fetch(url)", "new WebSocket(u)", 'require("fs")']
    allowed = ['import { readFileSync } from "node:fs"', 'import assert from "node:assert/strict"', '"network"']
    assert [form for form in caught if not NETWORK.search(form)] == []
    assert [form for form in allowed if NETWORK.search(form)] == []


# 11. Hygiene.


def test_trees_mirror_each_other(koans_run, solutions_run):
    assert tree_files(TRACK_DIR / "koans") == tree_files(TRACK_DIR / "solutions")
    for path in tree_test_files(TRACK, "koans"):
        assert meditations(path.read_text(encoding="utf-8"), TYPESCRIPT) == meditations(
            tree_text("solutions", path.name), TYPESCRIPT
        )

    def per_file(run: VitestRun) -> Counter[str]:
        return Counter(Path(path).name for path, _line in run.results)

    assert per_file(koans_run) == per_file(solutions_run)


@pytest.mark.parametrize("tree", TREES)
def test_every_koan_has_a_meditation(tree):
    missing = []
    for path in tree_test_files(TRACK, tree):
        text = path.read_text(encoding="utf-8")
        missing.extend(
            f"{tree}/{path.name}:{line}"
            for line, said in zip(lines_of(text), meditations(text, TYPESCRIPT))
            if not (said or "").strip()
        )
    assert missing == []


def test_no_personal_paths_in_tracked_files():
    scoped = [path for path in tracked_files() if shown(path).startswith("typescript/")]
    assert scoped
    assert personal_path_hits(scoped) == []


def test_native_runtime_suite_passes(runtime_run):
    assert runtime_run.returncode == 0, runtime_run.stdout[-3000:]


CHECKS_FILES = [p for p in sorted((TRACK_DIR / "checks").glob("*_checks.ts")) if in_scope(p.name)]


def cases_text(path: Path) -> str:
    text = path.read_text(encoding="utf-8")
    start = text.find("export const CASES = [")
    assert start > -1, f"{path.name} exports CASES"
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
def test_checks_never_import_vitest(path):
    assert IMPORTS_VITEST.findall(path.read_text(encoding="utf-8")) == []


@pytest.mark.parametrize("call", VERDICTS, ids=lambda c: case_id(c.file))
def test_fix_koan_follows_its_verdict(call):
    text = tree_text("koans", Path(call.test_path).name)
    if call.answer == "fine":
        koan = enclosing_koan(text, call.line, TYPESCRIPT)
    else:
        koan = fix_koan_line(text, call.line, TYPESCRIPT)
    stem = Path(call.file).stem
    assert [m["stem"] for m in RUN_CHECKS.finditer(koan_body(text, koan, TYPESCRIPT))] == [stem]
    assert (TRACK_DIR / "checks" / f"{stem}_checks.ts").is_file()


@pytest.mark.parametrize("call", VERDICTS, ids=lambda c: case_id(c.file))
def test_review_meditations_use_the_frozen_wording(call):
    text = tree_text("koans", Path(call.test_path).name)
    verdict_koan = enclosing_koan(text, call.line, TYPESCRIPT)
    assert meditation(text, verdict_koan, TYPESCRIPT) == VERDICT_MEDITATION.format(file=call.file)
    if call.answer != "fine":
        fix_koan = fix_koan_line(text, call.line, TYPESCRIPT)
        assert meditation(text, fix_koan, TYPESCRIPT) == FIX_MEDITATION.format(file=call.file)


SOURCE_TESTS = [p for p in sorted(SOURCE.glob(TYPESCRIPT.test_glob)) if in_scope(p.name)]


@pytest.mark.parametrize("path", SOURCE_TESTS, ids=lambda p: case_id(p.name))
def test_predicts_never_use_toBe(path):
    assert static_hits([path], TO_BE) == []


@pytest.mark.parametrize("path", SOURCE_TESTS, ids=lambda p: case_id(p.name))
def test_koan_files_never_import_a_review_module(path):
    assert static_hits([path], IMPORTS_REVIEW) == []


REVIEW_FILES = [p for p in sorted((TRACK_DIR / "koans" / "review").glob("*.ts")) if in_scope(p.name)]


@pytest.mark.parametrize("path", REVIEW_FILES, ids=lambda p: case_id(p.name))
def test_review_files_have_no_line_comments(path):
    [syntax] = syntax_of([path]).values()
    assert syntax.line_comments == (), "a // comment survives into the learner's file"


def track_sources() -> list[Path]:
    """Every .ts file of the track that is not an installed package or a staged variant."""
    top = [entry for entry in sorted(TRACK_DIR.iterdir()) if entry.name not in UNTRACKED]
    nested = [path for entry in top if entry.is_dir() for path in sorted(entry.rglob("*.ts"))]
    return [*(entry for entry in top if entry.suffix == ".ts"), *nested]


def test_no_non_erasable_syntax():
    found = syntax_of(track_sources())
    assert len(found) > 10
    hits = [f"{shown(path)}:{line}: {what}" for path, syntax in found.items() for line, what in syntax.non_erasable]
    assert hits == []


def test_learner_commands_are_frozen():
    package = json.loads((TRACK_DIR / "package.json").read_text(encoding="utf-8"))
    config = (TRACK_DIR / "vitest.config.ts").read_text(encoding="utf-8")
    assert package["dependencies"] == {"vitest": "4.1.12"}
    assert package["devDependencies"]["typescript"] == "5.9.3"
    assert re.fullmatch(r"24\.\d+\.\d+", package["devDependencies"]["@types/node"])
    assert package["engines"] == {"node": ">=24"}
    assert package["scripts"]["test"] == "vitest run"
    assert "bail:" in config and "KOANS_DIR" in config
    section = readme_part("## The TypeScript track")
    code_blocks = "\n".join(readme_blocks(section))
    for command in SETUP_COMMANDS:
        assert command in code_blocks, command
    runtime = "\n".join(p.read_text(encoding="utf-8") for p in (TRACK_DIR / "support").glob("*.ts"))
    for form in FOOTER_FORMS:
        for piece in (p for p in re.split(r"\{\w+\}", form) if len(p) >= 10):
            assert piece in runtime, piece
            assert piece in section, piece


README = ROOT / "README.md"
TRACK_HEADING = "## The TypeScript track"
SETUP_COMMANDS = ("cd typescript", "npm ci", "npm test", "npx vitest run koans/<file>", "npx vitest run koans/<file>:<line>")
FOOTER_FORMS = (
    'Replace __ with "fine", or the number of the line with the bug in {path}.',
    "Not fine: {path} has a bug. Write the number of the line where it is.",
    'Read {path} again: it is fine. Write "fine".',
    "Not that line. Look again at {path}.",
    "A hidden case still fails: {label}",
    "{answered} of {total} koans answered. Run the whole suite for the rest.",
    "All {total} koans pass. Start again with: git checkout -- koans/",
)


def readme_part(heading: str | None) -> str:
    text = README.read_text(encoding="utf-8")
    if heading is None:
        return text.split("\n## ", 1)[0]
    return re.search(rf"^{re.escape(heading)}\n.*?(?=^## |\Z)", text, re.S | re.M)[0]


def readme_blocks(section: str) -> list[str]:
    return re.findall(r"^```[^\n]*\n(.*?)^```", section, re.S | re.M)


def koan_total() -> tuple[int, int]:
    files = sorted((TRACK_DIR / "koans").glob("[0-9][0-9]_*_test.ts"))
    return sum(len(koan_lines(f.read_text(encoding="utf-8"), TYPESCRIPT)) for f in files), len(files)


def test_readme_counts_match_the_koans():
    koans, chapters = koan_total()
    intro, section = readme_part(None), readme_part(TRACK_HEADING)
    assert f"The TypeScript track has {koans} koans in {chapters} chapters" in intro
    totals = {total for _, total in re.findall(r"(\d+) of (\d+) koans", section)}
    assert totals == {str(koans)}
    assert f"All {koans} koans pass" in section


def test_readme_first_footer_is_what_the_first_blank_prints():
    text = (TRACK_DIR / "koans" / "00_how_review_koans_work_test.ts").read_text(encoding="utf-8")
    first = koan_lines(text, TYPESCRIPT)[0]
    blank = next(n for n, line in enumerate(text.splitlines(), 1) if n > first and BLANK.search(line))
    expected = (
        "Replace __ with the value that makes this true.\n"
        f"{'-' * 31} The master says {'-' * 32}\n"
        f"Meditate on koans/00_how_review_koans_work_test.ts:{blank}\n"
        f"    {meditation(text, first, TYPESCRIPT)}\n"
        f"0 of {koan_total()[0]} koans answered.\n"
    )
    assert expected in readme_blocks(readme_part(TRACK_HEADING))
