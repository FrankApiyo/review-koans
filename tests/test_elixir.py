"""The eleven self-tests for the Elixir track. REVIEW_KOANS_CHAPTER=NN narrows them to one chapter."""

import hashlib
import re
import subprocess
import sys
from collections import Counter
from dataclasses import dataclass
from pathlib import Path

import pytest

import traces
from dialects import ELIXIR
from elixir_runner import ELIXIR as TRACK_DIR
from elixir_runner import KoansResult, MixRun, koans_result, run_mix, stage
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
    tracked_files,
    verdict_calls,
)

TRACK = "elixir"
TREES = ("koans", "solutions")
SOURCE = TRACK_DIR / "source"
ALLOWLIST = ROOT / "tests" / "allowlist.txt"
COURSE_FILES = files_under(TRACK_DIR, ("source", "checks", "lib/course", "traces"), (".ex", ".exs"))
NETWORK = re.compile(r":gen_tcp|:gen_udp|:httpc|:ssl\b|:inet\.|\bReq\.|Finch|\bMint\.")
REAL_CLOCK = re.compile(
    r"Process.sleep|:timer\.(sleep|send_after)|Process.send_after"
    r"|:erlang\.(send_after|start_timer|monotonic_time|system_time)|System\.(monotonic|system|os)_time"
    r"|(Naive)?DateTime\.utc_now|Date\.utc_today|:os\.timestamp|^\s*after\b"
)
SERVES = re.compile(r"server:\s*true")
PERSONAL = ("/" + "Users/", "/" + "home/")
VERDICT_ENDING = "Write :fine, or the line number of the bug."
FIX_MEDITATION = "Fix the bug in koans/review/{file} in place. The hidden checks name what still fails."
LEARNER_TEST_ALIAS = 'test: "test --max-requires 1"'
BLANK = re.compile(r"(?<!\w)__(?!\w)")
RUN_CHECKS = re.compile(r"run_checks\((?P<checks>[\w.]+),\s*(?P<review>[\w.]+)\)")
MODULE = re.compile(r"^defmodule (?P<name>[\w.]+) do$", re.M)
USES_CHECKS = re.compile(r"^\s*use Koans\.Checks, review: (?P<review>[\w.]+)$")
EQUALITY = re.compile(r"==|\bmatch\?")
HIDDEN = "Koans.HiddenCase:"

REVIEWS = review_renders(TRACK)
VERDICTS = verdict_calls(TRACK)


def shown(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def tree_text(tree: str, name: str) -> str:
    return (TRACK_DIR / tree / name).read_text(encoding="utf-8")


def tree_reviews(tree: str) -> dict[str, str]:
    return {path.name: path.read_text(encoding="utf-8") for path in sorted((TRACK_DIR / tree / "review").glob("*.ex"))}


def review_module(file: str) -> str:
    return MODULE.search((SOURCE / "review" / file).read_text(encoding="utf-8"))["name"]


def verdict_for(file: str):
    [call] = [call for call in VERDICTS if call.file == file]
    return call


def mix_test(paths: list[str], *, koans_dir: str, build_path: str) -> MixRun:
    return run_mix(["test", "--force", *paths], koans_dir=koans_dir, build_path=build_path, verify=True)


def whole_tree(tree: str, build_path: str) -> MixRun:
    paths = [f"{tree}/{path.name}" for path in tree_test_files(TRACK, tree)] if chapter_filter() else []
    return mix_test(paths, koans_dir=tree, build_path=build_path)


def kinds_through(run: MixRun, path: str, text: str, koan: int) -> dict[int, str | None]:
    return {line: run.results.get((path, line)) for line in koan_lines(text) if line <= koan}


def earlier_are_ok(kinds: dict[int, str | None], koan: int) -> bool:
    return all(kind == "ok" for line, kind in kinds.items() if line < koan)


@pytest.fixture(scope="module")
def solutions_run() -> MixRun:
    return whole_tree("solutions", "_build_solutions")


@pytest.fixture(scope="module")
def koans_run() -> MixRun:
    return whole_tree("koans", "_build")


# 1. Every solution passes.


def test_solutions_reach_enlightenment(solutions_run):
    total = sum(len(koan_lines(p.read_text(encoding="utf-8"))) for p in (TRACK_DIR / "solutions").glob("*_test.exs"))
    ran = sum(len(koan_lines(p.read_text(encoding="utf-8"))) for p in tree_test_files(TRACK, "solutions"))
    footer = f"All {total} koans pass." if ran == total else f"{ran} of {total} koans answered. Run the whole suite for the rest."
    assert solutions_run.returncode == 0, solutions_run.output[-3000:]
    assert footer in solutions_run.output
    assert list(solutions_run.results.values()) == ["ok"] * ran


# 2. Every unsolved koan fails as a blank or a hidden case.


def test_unsolved_koans_fail_as_blank_or_hidden_case(koans_run):
    expected = {}
    for path in tree_test_files(TRACK, "koans"):
        text, test_path = path.read_text(encoding="utf-8"), f"koans/{path.name}"
        fixes = {fix_koan_line(text, c.line) for c in VERDICTS if c.test_path == test_path and c.answer != "fine"}
        for line in koan_lines(text):
            expected[(test_path, line)] = f"{HIDDEN}exploit" if line in fixes else "Koans.Blank"
    assert koans_run.returncode != 0
    assert koans_run.results == expected, koans_run.output[-3000:]


# 3. Every blank and every fix block fails alone.


@dataclass(frozen=True)
class BlankVariant:
    id: str
    staged: str
    text: str
    line: int


def renamed(text: str, number: int) -> str:
    assert len(MODULE.findall(text)) == 1, "a test file defines only its test module"
    return MODULE.sub(lambda m: f"defmodule {m['name']}.V{number:04d} do", text, count=1)


def blank_variants() -> list[BlankVariant]:
    variants = []
    for path in sorted(SOURCE.glob(ELIXIR.test_glob)):
        if not in_scope(path.name):
            continue
        text = path.read_text(encoding="utf-8")
        for blank in blanks(shown(path), text, ELIXIR):
            number = len(variants) + 1
            variant, line = render_test_variant(shown(path), text, ELIXIR, REVIEWS, blank.index)
            staged = f"v{number:04d}_{path.name}"
            variants.append(BlankVariant(case_id(path.name, f"n{blank.index}"), staged, renamed(variant, number), line))
    return variants


BLANK_VARIANTS = blank_variants()


@pytest.fixture(scope="module")
def batch_run() -> MixRun:
    koans_dir = stage("batch", {v.staged: v.text for v in BLANK_VARIANTS}, tree_reviews("solutions"))
    return mix_test([], koans_dir=koans_dir, build_path="_build_variants")


@pytest.mark.parametrize("variant", BLANK_VARIANTS, ids=lambda v: v.id)
def test_each_blank_fails_alone(variant, batch_run):
    lines = variant.text.splitlines()
    koans_part = "\n".join(lines[koan_lines(variant.text)[0] - 1 :])
    assert len(BLANK.findall(koans_part)) == 1 and BLANK.search(lines[variant.line - 1]), "one blank, on its line"
    koan = enclosing_koan(variant.text, variant.line)
    kinds = kinds_through(batch_run, f"_variants/batch/{variant.staged}", variant.text, koan)
    assert kinds[koan] == "Koans.Blank", batch_run.output[-3000:]
    assert earlier_are_ok(kinds, koan), kinds


def test_first_blank_fails_on_its_own_line(batch_run):
    if not BLANK_VARIANTS:
        pytest.skip("no blanks in scope")
    first = BLANK_VARIANTS[0]
    assert koans_result(batch_run) == KoansResult("Koans.Blank", f"_variants/batch/{first.staged}", first.line)


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


def run_review_variant(case: ReviewVariant) -> tuple[dict[int, str | None], int, str]:
    """Stages the solutions with one review block swapped; returns kinds up to the review's checks koan."""
    source = SOURCE / "review" / case.file
    variant = render_review_with(shown(source), source.read_text(encoding="utf-8"), ELIXIR, case.block, case.half)
    reviews = tree_reviews("solutions")
    assert variant != reviews[case.file], "the variant leaves the solved review unchanged"
    call = verdict_for(case.file)
    name = Path(call.test_path).name
    text = tree_text("solutions", name)
    koans_dir = stage("one", {name: text}, {**reviews, case.file: variant})
    run = mix_test([f"{koans_dir}/{name}"], koans_dir=koans_dir, build_path="_build_variants")
    [answered] = [v for v in rendered_verdicts(text) if v.file == case.file]
    koan = enclosing_koan(text, answered.line) if call.answer == "fine" else fix_koan_line(text, answered.line)
    return kinds_through(run, f"{koans_dir}/{name}", text, koan), koan, run.output


@pytest.mark.parametrize("case", FIX_BLOCKS, ids=lambda c: c.id)
def test_each_fix_block_fails_alone(case):
    kinds, koan, output = run_review_variant(case)
    assert (kinds[koan] or "").startswith(HIDDEN), output[-3000:]
    assert earlier_are_ok(kinds, koan), kinds


# 4. Every wrong half fails as a hidden case; every alternative passes.


@pytest.mark.parametrize("case", WRONG_HALVES, ids=lambda c: c.id)
def test_each_wrong_half_fails_as_hidden_case(case):
    kinds, koan, output = run_review_variant(case)
    expected = f"{HIDDEN}twin" if case.tag == "refuses" else HIDDEN
    assert (kinds[koan] or "").startswith(expected), output[-3000:]
    assert earlier_are_ok(kinds, koan), kinds


@pytest.mark.parametrize("case", ALT_HALVES, ids=lambda c: c.id)
def test_each_alt_half_passes(case):
    kinds, koan, output = run_review_variant(case)
    assert set(kinds.values()) == {"ok"}, output[-3000:]


@pytest.mark.parametrize("case", GUARD_MUTANTS, ids=lambda c: c.id)
def test_each_guard_mutant_fails_as_hidden_case(case):
    kinds, koan, output = run_review_variant(case)
    assert (kinds[koan] or "").startswith(HIDDEN), output[-3000:]
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
    assert rendered.answer == ELIXIR.value_blank
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


@pytest.mark.parametrize("tree, build_path", [("koans", "_build"), ("solutions", "_build_solutions")])
def test_trees_compile_without_warnings(tree, build_path):
    run = run_mix(["compile", "--force", "--warnings-as-errors"], koans_dir=tree, build_path=build_path)
    assert run.returncode == 0, run.output
    assert "warning:" not in run.output, run.output


def test_test_files_load_without_warnings(solutions_run, koans_run):
    assert "warning:" not in solutions_run.output, solutions_run.output
    assert "warning:" not in koans_run.output, koans_run.output


# 9 and 10. No network and no real clock in course code.


def test_no_network_in_course_code():
    assert static_hits(COURSE_FILES, NETWORK) == []


def test_endpoint_never_serves():
    if not (TRACK_DIR / "lib" / "support" / "endpoint.ex").exists():
        pytest.skip("the track has no endpoint yet")
    configs = [*files_under(TRACK_DIR, ("lib", "config"), (".ex", ".exs")), TRACK_DIR / "mix.exs"]
    assert static_hits(configs, SERVES) == []


def test_no_real_clock_in_course_code():
    assert static_hits(COURSE_FILES, REAL_CLOCK, ALLOWLIST) == []


# 11. Hygiene.


def tree_files(tree: str) -> list[str]:
    base = TRACK_DIR / tree
    return sorted(
        p.relative_to(base).as_posix()
        for p in base.rglob("*")
        if p.is_file() and not any(part.startswith(".") for part in p.relative_to(base).parts)
    )


def meditations(text: str) -> list[str | None]:
    return [meditation(text, line) for line in koan_lines(text)]


def test_trees_mirror_each_other(koans_run, solutions_run):
    assert tree_files("koans") == tree_files("solutions")
    for path in tree_test_files(TRACK, "koans"):
        assert meditations(path.read_text(encoding="utf-8")) == meditations(tree_text("solutions", path.name))

    def per_file(run: MixRun) -> Counter[str]:
        return Counter(Path(path).name for path, _line in run.results)

    assert per_file(koans_run) == per_file(solutions_run)


@pytest.mark.parametrize("tree", TREES)
def test_every_koan_has_a_meditation(tree):
    missing = []
    for path in tree_test_files(TRACK, tree):
        text = path.read_text(encoding="utf-8")
        missing.extend(
            f"{tree}/{path.name}:{line}"
            for line, said in zip(koan_lines(text), meditations(text))
            if not (said or "").strip()
        )
    assert missing == []


def test_no_personal_paths_in_tracked_files():
    found = [shown(p) for p in tracked_files() if any(n.encode() in p.read_bytes() for n in PERSONAL)]
    assert found == []


def test_every_mix_test_is_forced():
    with pytest.raises(ValueError, match="--force"):
        run_mix(["test", "_variants/none"], koans_dir="_variants/none", build_path="_build_variants")


def test_native_runtime_suite_passes():
    run = run_mix(["test", "--force"], koans_dir="verify", build_path="_build_verify")
    assert run.returncode == 0, run.output[-3000:]


def test_review_files_are_formatted():
    files = [shown(p).removeprefix("elixir/") for tree in TREES for p in sorted((TRACK_DIR / tree / "review").glob("*.ex"))]
    run = run_mix(["format", "--check-formatted", *files], koans_dir="koans", build_path="_build")
    assert run.returncode == 0, run.output


CHECKS_FILES = [p for p in sorted((TRACK_DIR / "checks").glob("*_checks.ex")) if in_scope(p.name)]


def code_lines(path: Path) -> list[str]:
    lines = path.read_text(encoding="utf-8").splitlines()
    return [line for line in lines if line.strip() and not line.strip().startswith("#")]


def checked_reviews() -> dict[str, str]:
    """Each checks module mapped to the review module its `use Koans.Checks` names."""
    found = {}
    for path in sorted((TRACK_DIR / "checks").glob("*_checks.ex")):
        lines = code_lines(path)
        uses = USES_CHECKS.match(lines[1]) if len(lines) > 1 else None
        found[MODULE.match(lines[0])["name"]] = uses["review"] if uses else None
    return found


@pytest.mark.parametrize("path", CHECKS_FILES, ids=lambda p: case_id(p.name))
def test_checks_have_exploit_and_twin(path):
    text = path.read_text(encoding="utf-8")
    assert "{:exploit," in text and "{:twin," in text


@pytest.mark.parametrize("path", CHECKS_FILES, ids=lambda p: case_id(p.name))
def test_checks_list_twins_before_exploits(path):
    text = path.read_text(encoding="utf-8")
    assert -1 < text.rfind("{:twin,") < text.find("{:exploit,"), "a fix that refuses everything must fail as twin"


@pytest.mark.parametrize("path", CHECKS_FILES, ids=lambda p: case_id(p.name))
def test_checks_use_koans_checks_and_assert_by_match(path):
    review_file = path.name.removesuffix("_checks.ex") + ".ex"
    lines = code_lines(path)
    uses = USES_CHECKS.match(lines[1])
    assert uses and uses["review"] == review_module(review_file), lines[:2]
    assert [line.strip() for line in lines if EQUALITY.search(line)] == [], "assert with a match, not == or match?"


@pytest.mark.parametrize("call", VERDICTS, ids=lambda c: case_id(c.file))
def test_fix_koan_follows_its_verdict(call):
    text = tree_text("koans", Path(call.test_path).name)
    koan = enclosing_koan(text, call.line) if call.answer == "fine" else fix_koan_line(text, call.line)
    review = review_module(call.file)
    calls = [(m["checks"], m["review"]) for m in RUN_CHECKS.finditer(koan_body(text, koan))]
    assert [review for _checks, review in calls] == [review]
    assert checked_reviews().get(calls[0][0]) == review


@pytest.mark.parametrize("call", VERDICTS, ids=lambda c: case_id(c.file))
def test_review_meditations_use_the_frozen_wording(call):
    text = tree_text("koans", Path(call.test_path).name)
    assert (meditation(text, enclosing_koan(text, call.line)) or "").endswith(VERDICT_ENDING)
    if call.answer != "fine":
        assert meditation(text, fix_koan_line(text, call.line)) == FIX_MEDITATION.format(file=call.file)


def test_learner_commands_are_frozen():
    assert LEARNER_TEST_ALIAS in (TRACK_DIR / "mix.exs").read_text(encoding="utf-8")
