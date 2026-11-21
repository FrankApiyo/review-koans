import hashlib
import re
import subprocess
import sys

import pytest

import harness
from dialects import DIALECTS, ELIXIR, PYTHON, TS_FUNCTION_HEAD, TYPESCRIPT, dialect_for
from generate import (
    ROOT,
    Also,
    Blank,
    GenerationError,
    blanks,
    digest,
    main,
    render_code_blocks,
    render_review,
    render_review_with,
    render_test,
    render_test_variant,
    render_track,
    render_values,
)


def test_value_blank_renders_as_double_underscore_and_answer():
    src = "assert x == _a({:ok, 42})\n"
    assert render_values("t.exs", src, ELIXIR, solved=False) == "assert x == __\n"
    assert render_values("t.exs", src, ELIXIR, solved=True) == "assert x == {:ok, 42}\n"


@pytest.mark.parametrize(
    "answer",
    [
        '"a)"',
        '"""\n)\n"""',
        "'''\n)\n'''",
        "'a)'",
        "?)",
        '"#{f(1)}"',
        '"#{f("x)")}"',
        "?\\)",
        "1 # )\n",
        "f?(1)",
        "f(g(1), 2)",
    ],
)
def test_value_scanner_skips_parens_in_strings_heredocs_charlists_and_interpolation(answer):
    src = f"assert x == _a({answer})\nnext(1)\n"
    assert render_values("t.exs", src, ELIXIR, solved=False) == "assert x == __\nnext(1)\n"
    assert render_values("t.exs", src, ELIXIR, solved=True) == f"assert x == {answer}\nnext(1)\n"


def test_multiline_answer_collapses_to_one_blank():
    src = "assert x == _a(%{\n  a: 1\n})\n"
    assert render_values("t.exs", src, ELIXIR, solved=False) == "assert x == __\n"
    assert render_values("t.exs", src, ELIXIR, solved=True) == "assert x == %{\n  a: 1\n}\n"


def test_sigil_inside_answer_is_refused():
    with pytest.raises(GenerationError, match=r"t\.exs:1: sigil inside _a\("):
        render_values("t.exs", "assert x == _a(~s(a))\n", ELIXIR, solved=False)


def test_unclosed_answer_names_its_line():
    with pytest.raises(GenerationError, match=r"t\.exs:2: unclosed _a\("):
        render_values("t.exs", "a\nassert x == _a(1\n", ELIXIR, solved=False)


def test_marker_inside_a_longer_identifier_is_ignored():
    src = "foo_a(1)\n"
    assert render_values("t.exs", src, ELIXIR, solved=False) == src


BLOCK = "  test \"t\" do\n    # >>> answer\n    x = 1\n    y = 2\n    # <<<\n    assert y\n  end\n"


def test_code_block_renders_one_blank_line_and_body():
    assert render_code_blocks("t.exs", BLOCK, ELIXIR, solved=False) == (
        '  test "t" do\n    __()\n    assert y\n  end\n'
    )
    assert render_code_blocks("t.exs", BLOCK, ELIXIR, solved=True) == (
        '  test "t" do\n    x = 1\n    y = 2\n    assert y\n  end\n'
    )


def test_unclosed_block_names_its_line():
    with pytest.raises(GenerationError, match=r"t\.exs:3: unclosed"):
        render_code_blocks("t.exs", "a\nb\n  # >>> answer\nc\n", ELIXIR, solved=False)


def test_close_without_open_and_nested_open_are_refused():
    with pytest.raises(GenerationError, match=r"t\.exs:1: .*without"):
        render_code_blocks("t.exs", "# <<<\n", ELIXIR, solved=False)
    with pytest.raises(GenerationError, match=r"t\.exs:2: nested"):
        render_code_blocks("t.exs", "# >>> answer\n# >>> answer\n# <<<\n", ELIXIR, solved=False)


@pytest.mark.parametrize("kind", ["fix", "guard"])
def test_fix_and_guard_blocks_outside_review_files_are_refused(kind):
    with pytest.raises(GenerationError, match=rf"t\.exs:2: # >>> {kind} outside a review file"):
        render_code_blocks("t.exs", f"a\n# >>> {kind}\nx = 1\n# <<<\n", ELIXIR, solved=False)


def test_value_marker_inside_an_answer_block_is_refused():
    src = BLOCK.replace("    y = 2\n", "    y = _a(2)\n")
    assert src != BLOCK
    for render in (
        lambda: render_code_blocks("t.exs", src, ELIXIR, solved=False),
        lambda: render_test("t.exs", src, ELIXIR, {}),
        lambda: blanks("t.exs", src, ELIXIR),
    ):
        with pytest.raises(GenerationError, match=r"t\.exs:4: _a\( inside an answer block"):
            render()


def test_unknown_block_tag_is_refused():
    with pytest.raises(GenerationError, match=r"t\.exs:2: unknown block # >>> answr"):
        render_code_blocks("t.exs", "a\n# >>> answr\nx = 1\n# <<<\n", ELIXIR, solved=False)


def test_dialect_for_names_known_tracks():
    assert dialect_for("elixir") is DIALECTS["elixir"]
    with pytest.raises(KeyError, match="elixir"):
        dialect_for("cobol")


def test_lesson_extracts_dedented_moduledoc():
    text = 'defmodule A do\n  @moduledoc ~S"""\n  Look.\n    Indented.\n  """\nend\n'
    assert ELIXIR.lesson(text) == "Look.\n  Indented."
    assert ELIXIR.lesson("defmodule A do\nend\n") is None


def make_track(root, files):
    for rel, content in files.items():
        path = root / "elixir" / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")


R_SOURCE = "defmodule R do\n  # >>> guard\n  def f, do: 1\n  # === wrong: partial — returns nothing\n  # <<<\nend\n"
R_RENDER = "defmodule R do\n  def f, do: 1\nend\n"
SOURCE = {
    "source/01_a_test.exs": "assert x == _a(1)\n",
    "source/review/01_r.ex": R_SOURCE,
    "source/01_b_test.exs": 'verdict("01_r.ex", _a(:fine))\n',
}


def test_render_track_renders_every_source_file_to_both_trees(tmp_path):
    make_track(tmp_path, SOURCE)
    out = render_track("elixir", tmp_path)
    fine = digest("01_r.ex", "fine")
    source = hashlib.sha256(R_RENDER.encode()).hexdigest()[:10]
    assert out == {
        tmp_path / "elixir/koans/01_a_test.exs": "assert x == __\n",
        tmp_path / "elixir/solutions/01_a_test.exs": "assert x == 1\n",
        tmp_path / "elixir/koans/review/01_r.ex": R_RENDER,
        tmp_path / "elixir/solutions/review/01_r.ex": R_RENDER,
        tmp_path / "elixir/koans/01_b_test.exs": f'verdict("01_r.ex", __, "{fine}", "{source}")\n',
        tmp_path / "elixir/solutions/01_b_test.exs": f'verdict("01_r.ex", :fine, "{fine}", "{source}")\n',
    }


def test_check_reports_stale_missing_and_orphan(tmp_path, capsys):
    make_track(
        tmp_path,
        {
            **SOURCE,
            "koans/01_a_test.exs": "old\n",
            "solutions/01_a_test.exs": "assert x == 1\n",
            "koans/gone_test.exs": "x\n",
        },
    )
    assert main(["--check", "elixir"], root=tmp_path) == 1
    lines = capsys.readouterr().out.splitlines()
    assert "stale: elixir/koans/01_a_test.exs" in lines
    assert "missing: elixir/koans/review/01_r.ex" in lines
    assert "missing: elixir/solutions/review/01_r.ex" in lines
    assert "orphan: elixir/koans/gone_test.exs" in lines
    assert lines[-1] == "run: python tools/generate.py elixir"
    assert (tmp_path / "elixir/koans/01_a_test.exs").read_text() == "old\n"


def test_check_passes_after_generate(tmp_path, capsys):
    make_track(tmp_path, {**SOURCE, "koans/gone_test.exs": "x\n"})
    assert main(["elixir"], root=tmp_path) == 0
    assert (tmp_path / "elixir/koans/01_a_test.exs").read_text() == "assert x == __\n"
    assert not (tmp_path / "elixir/koans/gone_test.exs").exists()
    capsys.readouterr()
    assert main(["--check", "elixir"], root=tmp_path) == 0
    assert capsys.readouterr().out == ""


def test_no_tracks_means_every_track_whose_folder_exists(tmp_path):
    make_track(tmp_path, SOURCE)
    assert main([], root=tmp_path) == 0
    assert (tmp_path / "elixir/solutions/01_a_test.exs").read_text() == "assert x == 1\n"


def test_missing_source_folder_is_refused_and_trees_are_kept(tmp_path, capsys):
    make_track(tmp_path, {"koans/01_a_test.exs": "x\n", "solutions/01_a_test.exs": "x\n"})
    with pytest.raises(GenerationError, match=r"elixir/source is not a directory"):
        render_track("elixir", tmp_path)
    assert main(["elixir"], root=tmp_path) == 1
    assert "elixir/source is not a directory" in capsys.readouterr().err
    assert (tmp_path / "elixir/koans/01_a_test.exs").read_text() == "x\n"
    assert (tmp_path / "elixir/solutions/01_a_test.exs").read_text() == "x\n"


def test_dotfiles_are_neither_rendered_nor_orphans(tmp_path, capsys):
    make_track(
        tmp_path,
        {**SOURCE, "source/.DS_Store": "x", "koans/.DS_Store": "x", "solutions/review/.DS_Store": "x"},
    )
    assert tmp_path / "elixir/koans/.DS_Store" not in render_track("elixir", tmp_path)
    assert main(["elixir"], root=tmp_path) == 0
    assert (tmp_path / "elixir/koans/.DS_Store").exists()
    assert (tmp_path / "elixir/solutions/review/.DS_Store").exists()
    capsys.readouterr()
    assert main(["--check", "elixir"], root=tmp_path) == 0
    assert capsys.readouterr().out == ""


def test_generator_names_utf8_for_every_read_and_write(tmp_path):
    make_track(tmp_path, {"source/01_a_test.exs": "# é — ok\nassert x == _a(1)\n"})
    script = "import sys, generate; from pathlib import Path; sys.exit(generate.main(sys.argv[1:2], root=Path(sys.argv[2])))"
    for args in (["elixir"], ["--check"]):
        result = subprocess.run(
            [sys.executable, "-X", "warn_default_encoding", "-W", "error::EncodingWarning", "-c", script, *args, tmp_path],
            cwd=ROOT / "tools",
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, result.stderr
    koan = tmp_path / "elixir/koans/01_a_test.exs"
    assert koan.read_bytes() == "# é — ok\nassert x == __\n".encode("utf-8")


WRONG_HALVES = (
    "{i}# === wrong: refuses — refuses everything\n"
    "{i}raise \"no\"\n"
    "{i}# === wrong: partial — fixes half of it\n"
    "{i}x * 3\n"
)


def wrongs(indent):
    return WRONG_HALVES.format(i=indent)


CART = (
    "defmodule Review.Cart do\n"
    "  def add(items, qty)\n"
    "      # >>> fix\n"
    "      when qty >= 0,\n"
    "      # === fixed\n"
    "      when qty > 0,\n"
    "      # === wrong: refuses — refuses every quantity\n"
    "      when false,\n"
    "      # === wrong: partial — off by one the other way\n"
    "      when qty > 1,\n"
    "      # === alt: the comparison written the other way round\n"
    "      when 0 < qty,\n"
    "      # <<<\n"
    "      do: {:ok, [qty | items]}\n"
    "end\n"
)


def cart_with(guard):
    return (
        "defmodule Review.Cart do\n"
        "  def add(items, qty)\n"
        f"      {guard}\n"
        "      do: {:ok, [qty | items]}\n"
        "end\n"
    )


def test_digest_vectors():
    assert digest("cart.ex", 14) == "d5882bb7c9"
    assert digest("cart.ex", 15) == "886fdfa4ac"
    assert digest("cart.ex", "fine") == "dc2c050639"


def test_fix_block_renders_buggy_and_fixed_halves_without_markers():
    review = render_review("cart.ex", CART, ELIXIR)
    assert review.koans == cart_with("when qty >= 0,")
    assert review.solutions == cart_with("when qty > 0,")
    [block] = review.blocks
    assert (block.kind, block.source_line, block.koans_start) == ("fix", 3, 3)
    assert block.buggy == ("      when qty >= 0,",)
    assert block.fixed == ("      when qty > 0,",)
    assert [(h.kind, h.tag, h.description, h.lines) for h in block.halves] == [
        ("wrong", "refuses", "refuses every quantity", ("      when false,",)),
        ("wrong", "partial", "off by one the other way", ("      when qty > 1,",)),
        ("alt", None, "the comparison written the other way round", ("      when 0 < qty,",)),
    ]
    assert review.accepted == {3}
    assert review.source_digest == hashlib.sha256(review.koans.encode()).hexdigest()[:10]


@pytest.mark.parametrize("missing", ["refuses", "partial"])
def test_fix_block_needs_refuses_and_partial_wrong_halves(missing):
    kept = [line for line in CART.splitlines(keepends=True) if f"wrong: {missing}" not in line]
    with pytest.raises(GenerationError, match=rf"cart\.ex:3: fix block needs a wrong: {missing} half"):
        render_review("cart.ex", "".join(kept), ELIXIR)


def test_render_review_with_substitutes_one_half():
    assert render_review_with("cart.ex", CART, ELIXIR, 0, 0) == cart_with("when false,")
    assert render_review_with("cart.ex", CART, ELIXIR, 0, 2) == cart_with("when 0 < qty,")
    assert render_review_with("cart.ex", CART, ELIXIR, 0, None) == cart_with("when qty >= 0,")
    assert render_review_with("fine.ex", FINE, ELIXIR, 0, 0) == FINE_RENDER.replace("[qty | items]", "items")


def test_accepted_set_is_buggy_span_without_blank_lines():
    src = (
        "defmodule R do\n"
        "  def f(x) do\n"
        "    # >>> fix\n"
        "    y = x + 1\n"
        "\n"
        "    y * 2\n"
        "    # === fixed\n"
        "    x * 2\n" + wrongs("    ") + "    # <<<\n"
        "  end\n"
        "end\n"
    )
    review = render_review("r.ex", src, ELIXIR)
    assert review.koans.splitlines()[2:5] == ["    y = x + 1", "", "    y * 2"]
    assert review.accepted == {3, 5}


COUNTER = (
    "defmodule Review.Counter do\n"
    "  defp loop(total) do\n"
    "    receive do\n"
    "      {:add, n} -> loop(total + n)\n"
    "\n"
    "      # >>> fix\n"
    "<also>"
    "      # === fixed\n"
    "      {:stop, from} -> send(from, total)\n" + wrongs("      ") + "      # <<<\n"
    "    end\n"
    "  end\n"
    "end\n"
)


def counter(also):
    return COUNTER.replace("<also>", also)


def test_omission_accepts_line_before_after_and_function_head():
    review = render_review("counter.ex", counter(""), ELIXIR)
    lines = review.koans.splitlines()
    assert (lines[3], lines[5], lines[1]) == ("      {:add, n} -> loop(total + n)", "    end", "  defp loop(total) do")
    assert review.blocks[0].buggy == ()
    assert review.blocks[0].koans_start == 6
    assert review.accepted == {4, 6, 2}


def test_omission_walk_lowers_its_threshold_past_enclosing_lines():
    src = (
        "defmodule Review.Gen do\n"
        "  defmacro build(x) do\n"
        "    quote do\n"
        "      def helper, do: :ok\n"
        "    end\n"
        "    if x do\n"
        "      case x do\n"
        "        :a -> 1\n"
        "        # >>> fix\n"
        "        # === fixed\n"
        "        :b -> 2\n" + wrongs("        ") + "        # <<<\n"
        "      end\n"
        "    end\n"
        "  end\n"
        "end\n"
    )
    review = render_review("gen.ex", src, ELIXIR)
    assert review.koans.splitlines()[1] == "  defmacro build(x) do"
    assert review.accepted == {8, 9, 2}


def test_omission_with_no_head_is_refused():
    src = "x = 1\n# >>> fix\n# === fixed\n  y = 2\n" + wrongs("  ") + "# <<<\n"
    with pytest.raises(GenerationError, match=r"o\.ex:2: omission with no enclosing function or module head"):
        render_review("o.ex", src, ELIXIR)


def test_module_level_omission_accepts_module_head():
    src = (
        "defmodule Review.Worker do\n"
        "  use GenServer\n"
        "\n"
        "  def init(state), do: {:ok, state}\n"
        "  # >>> fix\n"
        "  # === fixed\n"
        "\n"
        "  def handle_info(_msg, state), do: {:noreply, state}\n" + wrongs("  ") + "  # <<<\n"
        "end\n"
    )
    review = render_review("worker.ex", src, ELIXIR)
    assert review.koans.splitlines()[3:5] == ["  def init(state), do: {:ok, state}", "end"]
    assert review.accepted == {4, 5, 1}


TWO_BLOCKS = (
    "defmodule Review.Form do\n"
    "  def a(x) do\n"
    "    # >>> fix\n"
    "    x + 1\n"
    "    # === fixed\n"
    "    x + 2\n" + wrongs("    ") + "    # <<<\n"
    "  end\n"
    "\n"
    "  def b(x) do\n"
    "    # >>> fix\n"
    "    x - 1\n"
    "    # === fixed\n"
    "    x - 2\n" + wrongs("    ") + "    # <<<\n"
    "  end\n"
    "end\n"
)


def test_accepted_set_is_union_of_fix_blocks():
    review = render_review("form.ex", TWO_BLOCKS, ELIXIR)
    assert [b.koans_start for b in review.blocks] == [3, 7]
    assert review.accepted == {3, 7}
    first_alone = render_review_with("form.ex", TWO_BLOCKS, ELIXIR, 0, None)
    assert first_alone.splitlines()[2:3] + first_alone.splitlines()[6:7] == ["    x + 1", "    x - 2"]
    second_alone = render_review_with("form.ex", TWO_BLOCKS, ELIXIR, 1, None)
    assert second_alone.splitlines()[2:3] + second_alone.splitlines()[6:7] == ["    x + 2", "    x - 1"]


def test_also_adds_the_matching_line_in_same_module():
    also = "      # also: receive do — a fair reviewer points at the receive\n"
    review = render_review("counter.ex", counter(also), ELIXIR)
    assert review.blocks[0].also == (Also("receive do", "a fair reviewer points at the receive", 3),)
    assert review.accepted == {2, 3, 4, 6}
    assert "also:" not in review.koans + review.solutions


@pytest.mark.parametrize("fragment", ["no such text", "end"])
def test_also_must_match_exactly_one_line(fragment):
    also = f"      # also: {fragment} — a reason\n"
    with pytest.raises(GenerationError, match=r"counter\.ex:7: also: .* must match exactly one line"):
        render_review("counter.ex", counter(also), ELIXIR)


def test_also_in_other_module_is_refused():
    other = "defmodule Other do\n  def other, do: :ok\nend\n\n"
    assert render_review("counter.ex", other + counter("      # also: receive do — same module\n"), ELIXIR).accepted == {
        6, 7, 8, 10
    }
    for fragment in ("def other", "defmodule Other"):
        src = other + counter(f"      # also: {fragment} — another module\n")
        with pytest.raises(GenerationError, match=r"counter\.ex:11: also: .* is not in the block's module"):
            render_review("counter.ex", src, ELIXIR)


def test_also_may_name_its_own_module_head():
    also = "      # also: defmodule Review.Counter — a reviewer may point at the module\n"
    review = render_review("counter.ex", counter(also), ELIXIR)
    assert review.blocks[0].also == (Also("defmodule Review.Counter", "a reviewer may point at the module", 1),)
    assert review.accepted == {1, 2, 4, 6}


@pytest.mark.parametrize("also", ["# also: receive do", "# also: receive do — ", "# also: receive do —"])
def test_also_needs_a_reason(also):
    with pytest.raises(GenerationError, match=r"counter\.ex:7: also: needs a reason"):
        render_review("counter.ex", counter(f"      {also}\n"), ELIXIR)


FINE = (
    "defmodule Review.Fine do\n"
    "  def add(items, qty) when qty > 0 do\n"
    "    # >>> guard\n"
    "    [qty | items]\n"
    "    # === wrong: partial — drops the quantity\n"
    "    items\n"
    "    # <<<\n"
    "  end\n"
    "end\n"
)
FINE_RENDER = "defmodule Review.Fine do\n  def add(items, qty) when qty > 0 do\n    [qty | items]\n  end\nend\n"


def test_guard_block_renders_shown_half_in_both_trees():
    review = render_review("fine.ex", FINE, ELIXIR)
    assert review.koans == review.solutions == FINE_RENDER
    [block] = review.blocks
    assert block.kind == "guard"
    assert block.buggy == block.fixed == ("    [qty | items]",)
    assert [(h.kind, h.tag) for h in block.halves] == [("wrong", "partial")]
    assert review.accepted == frozenset()


def test_guard_block_may_show_nothing_and_insert_lines_as_its_mutant():
    src = FINE.replace("    [qty | items]\n    # === wrong", "    # === wrong").replace("    items\n", "    raise \"no\"\n")
    assert src.count("[qty | items]") == 0
    review = render_review("fine.ex", src, ELIXIR)
    shown = "defmodule Review.Fine do\n  def add(items, qty) when qty > 0 do\n  end\nend\n"
    assert review.koans == review.solutions == shown
    assert render_review_with("fine.ex", src, ELIXIR, 0, 0) == shown.replace("do\n  end", 'do\n    raise "no"\n  end')


def test_guard_block_needs_a_wrong_half():
    no_wrong = FINE.replace("    # === wrong: partial — drops the quantity\n    items\n", "")
    assert "=== wrong" not in no_wrong
    with pytest.raises(GenerationError, match=r"fine\.ex:3: guard block needs a wrong: half"):
        render_review("fine.ex", no_wrong, ELIXIR)
    with_fixed = FINE.replace("    # === wrong", "    # === fixed\n    x\n    # === wrong")
    with pytest.raises(GenerationError, match=r"fine\.ex:3: guard block has no fixed half"):
        render_review("fine.ex", with_fixed, ELIXIR)


def test_fine_review_needs_a_guard_block():
    assert [block.kind for block in render_review("fine.ex", FINE, ELIXIR).blocks] == ["guard"]
    with pytest.raises(GenerationError, match=r"fine\.ex:1: fine review needs a guard block"):
        render_review("fine.ex", FINE_RENDER, ELIXIR)


def test_guard_wrong_halves_are_tagged_partial():
    with pytest.raises(GenerationError, match=r"fine\.ex:5: guard wrong: halves are tagged partial"):
        render_review("fine.ex", FINE.replace("wrong: partial", "wrong: refuses"), ELIXIR)


DOUBLE = (
    "defmodule Review.Double do\n"
    "  def f(x) do\n"
    "    # >>> fix\n"
    "    y = x + 1\n"
    "    y * 2\n"
    "    # === fixed\n"
    "    x * 2\n" + wrongs("    ") + "    # <<<\n"
    "  end\n"
    "end\n"
)


def reviews_of(**files):
    return {name: render_review(f"elixir/source/review/{name}", text, ELIXIR) for name, text in files.items()}


def verdict_test(answer, file="double.ex"):
    return f'  koan "verdict" do\n    verdict("{file}", _a({answer}))\n  end\n'


def test_verdict_renders_sorted_digests_and_hides_answer():
    reviews = reviews_of(**{"double.ex": DOUBLE})
    koans, solutions = render_test("t.exs", verdict_test(4), ELIXIR, reviews)
    digests = ",".join(sorted([digest("double.ex", 3), digest("double.ex", 4)]))
    assert digests != ",".join([digest("double.ex", 3), digest("double.ex", 4)])
    source = reviews["double.ex"].source_digest
    assert koans == f'  koan "verdict" do\n    verdict("double.ex", __, "{digests}", "{source}")\n  end\n'
    assert solutions == f'  koan "verdict" do\n    verdict("double.ex", 4, "{digests}", "{source}")\n  end\n'
    assert "_a(" not in koans
    assert not re.search(r"\b4\b", koans)


def test_verdict_answer_outside_accepted_set_is_refused():
    reviews = reviews_of(**{"double.ex": DOUBLE})
    with pytest.raises(GenerationError, match=r"t\.exs:2: verdict answer 9 is not an accepted line of double\.ex: \[3, 4\]"):
        render_test("t.exs", verdict_test(9), ELIXIR, reviews)


def test_verdict_must_name_an_existing_review_and_be_one_line():
    reviews = reviews_of(**{"double.ex": DOUBLE})
    with pytest.raises(GenerationError, match=r"t\.exs:2: verdict names review/gone\.ex, which does not exist"):
        render_test("t.exs", verdict_test(3, file="gone.ex"), ELIXIR, reviews)
    with pytest.raises(GenerationError, match=r"t\.exs:1: verdict must be one line"):
        render_test("t.exs", 'verdict("double.ex",\n  _a(3))\n', ELIXIR, reviews)
    with pytest.raises(GenerationError, match=r"t\.exs:2: verdict answer must be :fine or a line number"):
        render_test("t.exs", verdict_test("x"), ELIXIR, reviews)


def test_fine_verdict_requires_no_fix_block():
    reviews = reviews_of(**{"double.ex": DOUBLE, "fine.ex": FINE})
    koans, solutions = render_test("t.exs", verdict_test(":fine", file="fine.ex"), ELIXIR, reviews)
    expected = f'verdict("fine.ex", __, "{digest("fine.ex", "fine")}", "{reviews["fine.ex"].source_digest}")'
    assert expected in koans
    assert expected.replace("__", ":fine") in solutions
    with pytest.raises(GenerationError, match=r"t\.exs:2: fine\.ex has no fix block, so its verdict answer must be :fine"):
        render_test("t.exs", verdict_test(3, file="fine.ex"), ELIXIR, reviews)
    with pytest.raises(GenerationError, match=r"t\.exs:2: double\.ex has a fix block, so its verdict answer is a line"):
        render_test("t.exs", verdict_test(":fine"), ELIXIR, reviews)


def test_review_with_fix_block_needs_exactly_one_verdict(tmp_path):
    files = {
        "source/review/double.ex": DOUBLE,
        "source/review/fine.ex": FINE,
        "source/00_a_test.exs": verdict_test(":fine", file="fine.ex"),
    }
    make_track(tmp_path, files)
    with pytest.raises(GenerationError, match=r"elixir/source/review/double\.ex:3: no verdict names double\.ex"):
        render_track("elixir", tmp_path)
    make_track(tmp_path, {**files, "source/01_b_test.exs": verdict_test(3)})
    out = render_track("elixir", tmp_path)
    assert 'verdict("double.ex", 3, "' in out[tmp_path / "elixir/solutions/01_b_test.exs"]
    assert out[tmp_path / "elixir/koans/review/double.ex"] == render_review("double.ex", DOUBLE, ELIXIR).koans
    make_track(tmp_path, {"source/02_c_test.exs": verdict_test(4)})
    with pytest.raises(GenerationError, match=r"elixir/source/02_c_test\.exs:2: double\.ex already has a verdict"):
        render_track("elixir", tmp_path)


def test_fine_review_needs_exactly_one_verdict(tmp_path):
    make_track(tmp_path, {"source/review/fine.ex": FINE, "source/00_a_test.exs": "x\n"})
    with pytest.raises(GenerationError, match=r"elixir/source/review/fine\.ex:3: no verdict names fine\.ex"):
        render_track("elixir", tmp_path)
    make_track(tmp_path, {"source/01_b_test.exs": verdict_test(":fine", file="fine.ex")})
    out = render_track("elixir", tmp_path)
    assert 'verdict("fine.ex", :fine, "' in out[tmp_path / "elixir/solutions/01_b_test.exs"]
    make_track(tmp_path, {"source/02_c_test.exs": verdict_test(":fine", file="fine.ex")})
    with pytest.raises(GenerationError, match=r"elixir/source/02_c_test\.exs:2: fine\.ex already has a verdict"):
        render_track("elixir", tmp_path)


BLANKS_TEST = (
    'koan "a" do\n'
    "  assert 1 + 1 == _a(2)\n"
    "  y = _a(%{\n"
    "    a: 1\n"
    "  })\n"
    "end\n"
    'koan "b" do\n'
    "  # >>> answer\n"
    "  x = 1\n"
    "  # <<<\n"
    "  assert x == 1\n"
    "end\n"
    'koan "c" do\n'
    '  verdict("double.ex", _a(3))\n'
    "end\n"
)


def test_blank_variants_leave_exactly_one_blank():
    reviews = reviews_of(**{"double.ex": DOUBLE})
    assert blanks("t.exs", BLANKS_TEST, ELIXIR) == [
        Blank("value", 0, 2),
        Blank("value", 1, 3),
        Blank("code", 2, 8),
        Blank("verdict", 3, 14),
    ]
    _, solutions = render_test("t.exs", BLANKS_TEST, ELIXIR, reviews)
    assert "__" not in solutions
    expected = {
        0: ("value", 2, "  assert 1 + 1 == __"),
        1: ("value", 3, "  y = __"),
        2: ("code", 8, "  __()"),
        3: ("verdict", 12, None),
    }
    for index, (kind, line, text) in expected.items():
        variant, at = render_test_variant("t.exs", BLANKS_TEST, ELIXIR, reviews, index)
        assert at == line, kind
        assert variant.count("__") == 1, kind
        assert "__" in variant.splitlines()[at - 1], kind
        if text:
            assert variant.splitlines()[at - 1] == text
    verdict_variant, at = render_test_variant("t.exs", BLANKS_TEST, ELIXIR, reviews, 3)
    assert verdict_variant.splitlines()[at - 1].startswith('  verdict("double.ex", __, "')
    assert verdict_variant.replace(", __, ", ", 3, ") == solutions


# Python dialect.

PYTHON_ANSWERS = ['")"', "')'", 'b")"', 'r"\\)"', '"""\n)\n"""', "(1, (2,))", "[1,  # )\n 2]"]


@pytest.mark.parametrize("answer", PYTHON_ANSWERS)
def test_python_value_blank_skips_parens_in_strings_bytes_raw_triple_quotes_and_comments(answer):
    src = f"assert x == _a({answer})\n"
    assert render_values("t_test.py", src, PYTHON, solved=False) == "assert x == __\n"
    assert render_values("t_test.py", src, PYTHON, solved=True) == f"assert x == {answer}\n"


def test_python_f_string_inside_answer_is_refused():
    with pytest.raises(GenerationError, match=r"t_test\.py:1: f-string inside _a\("):
        render_values("t_test.py", 'assert x == _a(f"{1}")\n', PYTHON, solved=False)


def test_python_unclosed_answer_names_its_line():
    with pytest.raises(GenerationError, match=r"t_test\.py:2: unclosed _a\("):
        render_values("t_test.py", "a\nassert x == _a(1\n", PYTHON, solved=False)


def test_python_code_block_renders_a_call_blank():
    src = "    # >>> answer\n    x = 1\n    # <<<\n"
    assert render_code_blocks("t_test.py", src, PYTHON, solved=False) == "    __()\n"
    assert render_code_blocks("t_test.py", src, PYTHON, solved=True) == "    x = 1\n"


def test_python_fine_verdict_renders_fine_token():
    source = "def f():\n    # >>> guard\n    return 1\n    # === wrong: partial — returns nothing\n    # <<<\n"
    reviews = {"f.py": render_review("review/f.py", source, PYTHON)}
    koans, solutions = render_test("t_test.py", 'verdict("f.py", _a(FINE))\n', PYTHON, reviews)
    fine, sha = digest("f.py", "fine"), reviews["f.py"].source_digest
    assert koans == f'verdict("f.py", __, "{fine}", "{sha}")\n'
    assert solutions == f'verdict("f.py", FINE, "{fine}", "{sha}")\n'


def py_fix(indent, fixed="x = 2"):
    return (
        f"{indent}# >>> fix\n{indent}# === fixed\n{indent}{fixed}\n"
        f"{indent}# === wrong: refuses — rejects\n{indent}raise ValueError\n"
        f"{indent}# === wrong: partial — half\n{indent}x = 3\n{indent}# <<<\n"
    )


def test_python_omission_accepts_line_before_after_and_def_head():
    src = "async def f(x):\n    a = 1\n" + py_fix("    ") + "    return a\n"
    review = render_review("o.py", src, PYTHON)
    assert review.accepted == {2, 3, 1}


def test_python_omission_in_a_method_accepts_the_def_not_the_class():
    src = "class C:\n    def m(self):\n        a = 1\n" + py_fix("        ") + "        return a\n"
    assert render_review("o.py", src, PYTHON).accepted == {3, 4, 2}


def test_python_class_level_omission_accepts_the_class_head():
    src = (
        "class C:\n    def a(self):\n        return 1\n\n"
        + py_fix("    ")
        + "\n    def b(self):\n        return 2\n"
    )
    review = render_review("o.py", src, PYTHON)
    assert review.accepted == {3, 6, 1}


def test_python_top_level_omission_is_refused():
    src = "x = 1\n" + py_fix("")
    with pytest.raises(GenerationError, match=r"o\.py:2: omission with no enclosing function or module head"):
        render_review("o.py", src, PYTHON)


def test_python_also_in_a_module_without_classes_is_accepted():
    src = (
        "def f(x):\n"
        "    # >>> fix\n"
        "    # also: y = 2 — equivalent\n"
        "    x = 1\n"
        "    # === fixed\n"
        "    x = 2\n"
        "    # === wrong: refuses — rejects\n"
        "    raise ValueError\n"
        "    # === wrong: partial — half\n"
        "    x = 3\n"
        "    # <<<\n"
        "    y = 2\n"
        "    return x\n"
    )
    review = render_review("o.py", src, PYTHON)
    assert [also.line for block in review.blocks for also in block.also] == [3]
    assert 3 in review.accepted


def test_python_lesson_is_the_module_docstring():
    text = '"""\nLook for: x\n    indented\n"""\n\ndef test_a():\n    pass\n'
    assert PYTHON.lesson(text) == "Look for: x\n    indented"
    assert PYTHON.lesson("def test_a():\n    pass\n") is None


def test_python_meditation_is_the_docstring_after_the_koan_head():
    text = 'def test_a(x):\n    """Why it fails"""\n    assert x\n\ndef test_b(x):\n    assert x\n'
    assert harness.meditation(text, 1, PYTHON) == "Why it fails"
    assert harness.meditation(text, 5, PYTHON) is None
    assert harness.koan_lines(text, PYTHON) == [1, 5]
    assert harness.fix_koan_line(text, 3, PYTHON) == 5
    assert harness.enclosing_koan(text, 3, PYTHON) == 1
    assert harness.koan_body(text, 1, PYTHON) == "\n".join(text.splitlines()[0:4])


PYTHON_TRACK = {
    "source/01_a_test.py": "def test_a():\n    assert 1 == _a(1)\n",
    "source/review/01_r.py": "def f():\n    # >>> guard\n    return 1\n    # === wrong: partial — nothing\n    # <<<\n",
    "source/01_b_test.py": 'def test_b():\n    verdict("01_r.py", _a(FINE))\n',
}


def test_python_track_generates_and_checks_clean(tmp_path, capsys):
    for rel, content in PYTHON_TRACK.items():
        path = tmp_path / "python" / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
    assert main([], root=tmp_path) == 0
    assert (tmp_path / "python/koans/01_a_test.py").read_text() == "def test_a():\n    assert 1 == __\n"
    assert "FINE" in (tmp_path / "python/solutions/01_b_test.py").read_text()
    capsys.readouterr()
    assert main(["--check", "python"], root=tmp_path) == 0
    assert capsys.readouterr().out == ""


def test_elixir_koan_helpers_are_unchanged():
    text = 'defmodule T do\n  koan "first" do\n    x\n  end\n\n  koan "second" do\n    y\n  end\nend\n'
    assert harness.koan_lines(text) == [2, 6]
    assert harness.meditation(text, 2) == "first"
    assert harness.meditation(text, 3) is None
    assert harness.fix_koan_line(text, 3) == 6
    assert harness.enclosing_koan(text, 7) == 6
    assert harness.koan_body(text, 2) == "\n".join(text.splitlines()[1:5])
    assert harness.KOAN_START is ELIXIR.koan_head


# TypeScript dialect.

TYPESCRIPT_ANSWERS = ['")"', "')'", '"a\\")"', "[1, [2, 3]]", '["traces/00_x.ts", 4]', "-0", "{ a: (1) }"]


@pytest.mark.parametrize("answer", TYPESCRIPT_ANSWERS)
def test_typescript_value_blank_skips_parens_in_strings(answer):
    src = f"expect(x).toEqual(_a({answer}))\n"
    assert render_values("t_test.ts", src, TYPESCRIPT, solved=False) == "expect(x).toEqual(__)\n"
    assert render_values("t_test.ts", src, TYPESCRIPT, solved=True) == f"expect(x).toEqual({answer})\n"


@pytest.mark.parametrize("answer", ["`a`", "/a/", "1 / 3", "1 // x\n"])
def test_typescript_template_regex_division_and_comment_inside_answer_are_refused(answer):
    with pytest.raises(GenerationError, match=r"t_test\.ts:1: (template literal|slash) inside _a\("):
        render_values("t_test.ts", f"expect(x).toEqual(_a({answer}))\n", TYPESCRIPT, solved=False)


def test_typescript_unclosed_answer_names_its_line():
    with pytest.raises(GenerationError, match=r"t_test\.ts:2: unclosed _a\("):
        render_values("t_test.ts", "a\nexpect(x).toEqual(_a(1\n", TYPESCRIPT, solved=False)


def test_typescript_code_block_renders_a_call_blank():
    src = "  // >>> answer\n  x = 1\n  // <<<\n"
    assert render_code_blocks("t_test.ts", src, TYPESCRIPT, solved=False) == "  __blank()\n"
    assert render_code_blocks("t_test.ts", src, TYPESCRIPT, solved=True) == "  x = 1\n"


TS_GUARD_REVIEW = "export function f() {\n  // >>> guard\n  return 1\n  // === wrong: partial — nothing\n  // <<<\n}\n"


def test_typescript_fine_verdict_renders_the_fine_string():
    reviews = {"f.ts": render_review("review/f.ts", TS_GUARD_REVIEW, TYPESCRIPT)}
    koans, solutions = render_test("t_test.ts", 'verdict("f.ts", _a("fine"))\n', TYPESCRIPT, reviews)
    fine, sha = digest("f.ts", "fine"), reviews["f.ts"].source_digest
    assert koans == f'verdict("f.ts", __, "{fine}", "{sha}")\n'
    assert solutions == f'verdict("f.ts", "fine", "{fine}", "{sha}")\n'


def ts_fix(indent, fixed="x = 2"):
    return (
        f"{indent}// >>> fix\n{indent}// === fixed\n{indent}{fixed}\n"
        f"{indent}// === wrong: refuses — rejects\n{indent}throw new Error()\n"
        f"{indent}// === wrong: partial — half\n{indent}x = 3\n{indent}// <<<\n"
    )


def test_typescript_fix_markers_use_double_slash():
    src = "export function f(x: number) {\n  // >>> fix\n  x = 1\n" + ts_fix("  ")[len("  // >>> fix\n") :] + "  return x\n}\n"
    review = render_review("o.ts", src, TYPESCRIPT)
    [block] = review.blocks
    assert (block.kind, block.buggy, block.fixed) == ("fix", ("  x = 1",), ("  x = 2",))
    assert "//" not in review.koans
    assert review.accepted == {2}


def test_typescript_omission_accepts_line_before_after_and_function_head():
    src = "export async function f(x: number) {\n  const a = 1\n" + ts_fix("  ") + "  return a\n}\n"
    assert render_review("o.ts", src, TYPESCRIPT).accepted == {2, 3, 1}


def test_typescript_omission_in_a_method_accepts_the_method_head():
    src = "export class C {\n  async m(x: number): Promise<number> {\n    const a = 1\n" + ts_fix("    ") + "    return a\n  }\n}\n"
    assert render_review("o.ts", src, TYPESCRIPT).accepted == {3, 4, 2}


def test_typescript_omission_in_an_arrow_const_accepts_the_const_line():
    src = "export const f = async (x: number) => {\n  const a = 1\n" + ts_fix("  ") + "  return a\n}\n"
    assert render_review("o.ts", src, TYPESCRIPT).accepted == {2, 3, 1}


def test_typescript_class_level_omission_accepts_the_class_head():
    src = (
        "export class C {\n  a() {\n    return 1\n  }\n\n"
        + ts_fix("  ")
        + "\n  b() {\n    return 2\n  }\n}\n"
    )
    assert render_review("o.ts", src, TYPESCRIPT).accepted == {4, 7, 1}


def test_typescript_indented_calls_are_not_function_heads():
    assert not TS_FUNCTION_HEAD.match("    run(job)")
    assert not TS_FUNCTION_HEAD.match("    super(x)")
    src = "export class W extends B {\n  constructor(job: Job) {\n    super(job)\n    run(job)\n" + ts_fix("      ") + "  }\n}\n"
    assert render_review("o.ts", src, TYPESCRIPT).accepted == {4, 5, 2}


@pytest.mark.parametrize(
    "line",
    [
        "function f(x) {",
        "export default async function f() {",
        "export const f = (x: number) => {",
        "let g = async x =>",
        "  get total(): number {",
        "  handle = async (e: Event) => {",
        "  static make(x: number) {",
        "  m<T>(x: T): T {",
        "export const f = <T,>(x: T) => {",
        "const g = async <T>(x: T): Promise<T> => {",
        "  async *items() {",
        "  *items() {",
        "  [Symbol.iterator]() {",
        "  readonly handle = (e: Event) => {",
        "  private readonly handle = async (e: Event) => {",
        "  static #make<T>(x: T) {",
    ],
)
def test_typescript_function_heads(line):
    assert TS_FUNCTION_HEAD.match(line)


@pytest.mark.parametrize("line", ["  if (x) {", "  for (const a of b) {", "  } catch (e) {", "  return (x) => {", "  while (x) {"])
def test_typescript_control_flow_is_not_a_function_head(line):
    assert not TS_FUNCTION_HEAD.match(line)


def test_typescript_lesson_is_the_leading_block_comment():
    text = '/*\nLook for: x\n  indented\n*/\nimport { test } from "vitest"\n'
    assert TYPESCRIPT.lesson(text) == "Look for: x\n  indented"
    assert TYPESCRIPT.lesson('import { test } from "vitest"\n/*\nx\n*/\n') is None


def test_typescript_meditation_unescapes_quotes():
    text = 'test("Write \\"fine\\", or x.", () => {\n  verdict()\n})\n\ntest("b", () => {\n  y()\n})\n'
    assert harness.meditation(text, 1, TYPESCRIPT) == 'Write "fine", or x.'
    assert harness.meditation(text, 2, TYPESCRIPT) is None
    assert harness.koan_lines(text, TYPESCRIPT) == [1, 5]
    assert harness.enclosing_koan(text, 6, TYPESCRIPT) == 5


TYPESCRIPT_TRACK = {
    "source/01_a_test.ts": 'test("a", () => {\n  expect(1).toEqual(_a(1))\n})\n',
    "source/review/01_r.ts": TS_GUARD_REVIEW,
    "source/01_b_test.ts": 'test("b", () => {\n  verdict("01_r.ts", _a("fine"))\n})\n',
}


def test_typescript_track_generates_and_checks_clean(tmp_path, capsys):
    for rel, content in TYPESCRIPT_TRACK.items():
        path = tmp_path / "typescript" / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
    assert main([], root=tmp_path) == 0
    koan = (tmp_path / "typescript/koans/01_a_test.ts").read_text()
    assert koan == 'test("a", () => {\n  expect(1).toEqual(__)\n})\n'
    assert '"fine"' in (tmp_path / "typescript/solutions/01_b_test.ts").read_text()
    capsys.readouterr()
    assert main(["--check", "typescript"], root=tmp_path) == 0
    assert capsys.readouterr().out == ""


def test_python_and_elixir_dialects_are_unchanged():
    assert list(DIALECTS) == ["elixir", "python", "typescript"]
    assert DIALECTS["python"] is PYTHON and DIALECTS["elixir"] is ELIXIR
    shape = lambda d: (d.comment, d.test_glob, d.review_glob, d.value_blank, d.fine, d.code_blank("t"))
    assert shape(ELIXIR) == ("#", "*_test.exs", "review/*.ex", "__", ":fine", "__()")
    assert shape(PYTHON) == ("#", "*_test.py", "review/*.py", "__", "FINE", "__()")
    heads = lambda d: (d.function_head.pattern, d.module_head.pattern, d.koan_head.pattern)
    assert heads(ELIXIR) == (r"^\s*(def|defp|defmacro|defmacrop)\b", r"^\s*defmodule\b", r'^\s*koan\s+"')
    assert heads(PYTHON) == (r"^\s*(async\s+)?def\b", r"^\s*class\b", r"^def test_\w+\(")


def test_typescript_omission_in_a_generic_method_accepts_the_method_head():
    src = "export class C {\n  m<T>(x: T): T {\n    const a = 1\n" + ts_fix("    ") + "    return a\n  }\n}\n"
    assert render_review("o.ts", src, TYPESCRIPT).accepted == {3, 4, 2}


def test_typescript_omission_in_a_generic_arrow_const_accepts_the_const_line():
    src = "export const f = <T,>(x: T) => {\n  const a = 1\n" + ts_fix("  ") + "  return a\n}\n"
    assert render_review("o.ts", src, TYPESCRIPT).accepted == {2, 3, 1}


def test_typescript_omission_in_a_callback_accepts_the_callback_opener():
    src = "export function f() {\n  setTimeout(() => {\n    const a = 1\n" + ts_fix("    ") + "    return a\n  })\n}\n"
    assert render_review("o.ts", src, TYPESCRIPT).accepted == {3, 4, 2}


@pytest.mark.parametrize("line", ["export abstract class C {", "export default class C {", "class C<T> {"])
def test_typescript_class_heads(line):
    assert TYPESCRIPT.module_head.match(line)


def test_bare_generate_skips_tracks_without_a_source_folder(tmp_path, capsys):
    for rel, content in PYTHON_TRACK.items():
        path = tmp_path / "python" / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
    (tmp_path / "typescript").mkdir()
    assert main([], root=tmp_path) == 0
    assert (tmp_path / "python/koans/01_a_test.py").is_file()
    assert main(["--check"], root=tmp_path) == 0
    capsys.readouterr()
    assert main(["typescript"], root=tmp_path) == 1
    assert "typescript/source is not a directory" in capsys.readouterr().err


@pytest.mark.parametrize(
    "line",
    ["const prices = await load()", "await ready", "export const prices = await load()", "for await (const x of xs) {}"],
)
def test_typescript_review_refuses_top_level_await(line):
    src = f"/** Doc. */\n{line}\n" + TS_GUARD_REVIEW
    with pytest.raises(GenerationError, match=r"review/f\.ts:2: top-level await in a review module"):
        render_review("review/f.ts", src, TYPESCRIPT)


def test_typescript_review_allows_await_inside_a_function():
    src = "export async function f() {\n  // >>> guard\n  return await g()\n  // === wrong: partial — nothing\n  // <<<\n}\n"
    render_review("review/f.ts", src, TYPESCRIPT)
    render_review("review/f.py", "x = 1  # await later\n" + "def f():\n    # >>> guard\n    return 1\n    # === wrong: partial — nothing\n    # <<<\n", PYTHON)
