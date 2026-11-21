"""Runs Vitest on the TypeScript track in a subprocess, reads its KOANS-TEST lines, and stages variants under _variants/."""

import json
import os
import re
import subprocess
from collections.abc import Iterable, Mapping
from dataclasses import dataclass
from pathlib import Path
from types import MappingProxyType

from elixir_runner import KoansResult, TEST_LINE
from elixir_runner import koans_result as _koans_result
from harness import ROOT, Variants, stage_variants, variants_locked

TS_DIR = ROOT / "typescript"
VARIANTS = TS_DIR / "_variants"
VITEST = TS_DIR / "node_modules" / ".bin" / "vitest"
TSC = TS_DIR / "node_modules" / ".bin" / "tsc"
QUIET = {"NO_COLOR": "1", "FORCE_COLOR": "0"}
INHERITED_NOISE = re.compile(r"VITEST.*|KOANS_.*|FORCE_COLOR|NODE_OPTIONS|TEST")
NO_ENV: Mapping[str, str] = MappingProxyType({})

# Parses each file with the pinned compiler and reports, per file: lines where a type node starts,
# constructs erasable-only TypeScript refuses, and lines holding a `//` comment.
SYNTAX_REPORT = r"""
import ts from "typescript"
import { readFileSync } from "node:fs"

const K = ts.SyntaxKind
const PROPERTY_MODIFIERS = new Set([K.PublicKeyword, K.PrivateKeyword, K.ProtectedKeyword, K.ReadonlyKeyword, K.OverrideKeyword])

function nonErasable(node) {
  if (ts.isEnumDeclaration(node)) return "enum"
  const augmentsGlobal = (node.flags & ts.NodeFlags.GlobalAugmentation) !== 0
  if (ts.isModuleDeclaration(node) && ts.isIdentifier(node.name) && !augmentsGlobal) return "namespace"
  if (ts.isImportEqualsDeclaration(node)) return "import ="
  if (ts.isDecorator(node)) return "decorator"
  if (ts.isParameter(node) && (node.modifiers ?? []).some((m) => PROPERTY_MODIFIERS.has(m.kind))) return "parameter property"
  return null
}

function report(path) {
  const text = readFileSync(path, "utf8")
  const file = ts.createSourceFile(path, text, ts.ScriptTarget.Latest, true, ts.ScriptKind.TS)
  const lineOf = (pos) => file.getLineAndCharacterOfPosition(pos).line + 1
  const types = new Set()
  const comments = new Set()
  const refused = []
  const noteComments = (ranges) => {
    for (const range of ranges ?? []) if (range.kind === K.SingleLineCommentTrivia) comments.add(lineOf(range.pos))
  }
  const visit = (node) => {
    if (ts.isTypeNode(node)) types.add(lineOf(node.getStart(file)))
    const what = nonErasable(node)
    if (what) refused.push([lineOf(node.getStart(file)), what])
    noteComments(ts.getLeadingCommentRanges(text, node.pos))
    noteComments(ts.getTrailingCommentRanges(text, node.end))
    for (const child of node.getChildren(file)) visit(child)
  }
  visit(file)
  return { types: [...types].sort((a, b) => a - b), nonErasable: refused, lineComments: [...comments].sort((a, b) => a - b) }
}

const paths = JSON.parse(readFileSync(0, "utf8"))
process.stdout.write(JSON.stringify(Object.fromEntries(paths.map((path) => [path, report(path)]))))
"""


@dataclass(frozen=True)
class VitestRun:
    returncode: int
    output: str
    results: dict[tuple[str, int], str]


@dataclass(frozen=True)
class Syntax:
    types: tuple[int, ...]
    non_erasable: tuple[tuple[int, str], ...]
    line_comments: tuple[int, ...]


def track_env(extra: Mapping[str, str] = NO_ENV) -> dict[str, str]:
    """The caller's environment without Vitest's, the koans' or colour settings, plus `extra`."""
    kept = {name: value for name, value in os.environ.items() if not INHERITED_NOISE.fullmatch(name)}
    return {**kept, **QUIET, **extra}


def run_in_track(
    command: list[str], *, env: Mapping[str, str] = NO_ENV, timeout: int = 900
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        cwd=TS_DIR,
        env=track_env(env),
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        timeout=timeout,
    )


def run_vitest(
    args: list[str],
    *,
    koans_dir: str = "koans",
    verify: bool = False,
    env: Mapping[str, str] = NO_ENV,
    timeout: int = 900,
) -> VitestRun:
    mode = {"KOANS_VERIFY": "1"} if verify else {}
    done = run_in_track([str(VITEST), "run", *args], env={**env, "KOANS_DIR": koans_dir, **mode}, timeout=timeout)
    results = {(m["path"], int(m["line"])): m["kind"] for m in TEST_LINE.finditer(done.stdout)}
    return VitestRun(done.returncode, done.stdout, results)


def koans_result(run: VitestRun) -> KoansResult | None:
    """The KOANS-RESULT line: the earliest failure at its blank's own line, or kind `ok`."""
    return _koans_result(run)


def stage_each(name: str, variants: Variants) -> str:
    """Recreates _variants/<name>/ with one vNNNN/ folder per variant, each holding its tests and review/."""
    return stage_variants(VARIANTS, name, variants)


def run_staged(name: str, variants: Variants) -> VitestRun:
    """Stages the variants and runs them in verify mode, holding _variants/.lock so concurrent runs take turns."""
    with variants_locked(VARIANTS):
        return run_vitest([], koans_dir=stage_each(name, variants), verify=True)


def syntax_of(paths: Iterable[Path]) -> dict[Path, Syntax]:
    """What the pinned TypeScript parser finds in each file: type nodes, non-erasable syntax and `//` comments."""
    wanted = [str(path) for path in paths]
    done = subprocess.run(
        ["node", "--input-type=module", "-e", SYNTAX_REPORT],
        cwd=TS_DIR,
        input=json.dumps(wanted),
        capture_output=True,
        text=True,
        timeout=600,
    )
    if done.returncode != 0:
        raise RuntimeError(f"the syntax report failed: {done.stderr}")
    found = json.loads(done.stdout)
    return {
        Path(path): Syntax(
            tuple(found[path]["types"]),
            tuple((line, what) for line, what in found[path]["nonErasable"]),
            tuple(found[path]["lineComments"]),
        )
        for path in wanted
    }
