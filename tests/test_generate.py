import pytest

from dialects import DIALECTS, ELIXIR, dialect_for
from generate import GenerationError, main, render_code_blocks, render_track, render_values


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
        "?\\n",
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


def test_fix_and_guard_blocks_pass_through_untouched():
    src = "# >>> fix\nx = 1\n# <<<\n# >>> guard\ny = 2\n# <<<\n"
    assert render_code_blocks("t.exs", src, ELIXIR, solved=False) == src
    assert render_code_blocks("t.exs", src, ELIXIR, solved=True) == src


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
        path.write_text(content)


SOURCE = {
    "source/01_a_test.exs": "assert x == _a(1)\n",
    "source/review/01_r.ex": "defmodule R do\nend\n",
}


def test_render_track_renders_every_source_file_to_both_trees(tmp_path):
    make_track(tmp_path, SOURCE)
    out = render_track("elixir", tmp_path)
    assert out == {
        tmp_path / "elixir/koans/01_a_test.exs": "assert x == __\n",
        tmp_path / "elixir/solutions/01_a_test.exs": "assert x == 1\n",
        tmp_path / "elixir/koans/review/01_r.ex": "defmodule R do\nend\n",
        tmp_path / "elixir/solutions/review/01_r.ex": "defmodule R do\nend\n",
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
