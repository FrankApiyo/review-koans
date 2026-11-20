import hashlib

import pytest

from review_koans import FINE, __
from review_koans.blank import Blank
from review_koans.verdict import Verdict, digest, review_path, verdict

CART = "def total(items):\n    result = 0\n    for item in items:\n        result = item\n    return result\n"
PATH = "koans/review/cart.py"


def _sha(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()[:10]


@pytest.fixture
def ask(tmp_path, monkeypatch):
    """A verdict call made from a koan file at koans/01_cart_test.py, with cwd one level up."""
    koans = tmp_path / "koans"
    (koans / "review").mkdir(parents=True)
    (koans / "review" / "cart.py").write_text(CART)
    monkeypatch.chdir(tmp_path)
    namespace = {"verdict": verdict}
    source = "def ask(file, answer, digests, source_digest):\n    verdict(file, answer, digests, source_digest)\n"
    exec(compile(source, str(koans / "01_cart_test.py"), "exec"), namespace)
    return namespace["ask"]


BUGGY = ",".join(digest("cart.py", line) for line in (4, 3))
FINE_DIGESTS = digest("cart.py", "fine")


def _refusal(ask, answer, digests, source_digest=_sha(CART)):
    with pytest.raises(Verdict) as raised:
        ask("cart.py", answer, digests, source_digest)
    return str(raised.value)


def test_digest_matches_the_generator_vectors():
    assert digest("cart.ex", 14) == "d5882bb7c9"
    assert digest("cart.ex", "fine") == "dc2c050639"


def test_review_path_is_the_koan_folder_relative_to_cwd(ask, tmp_path):
    assert review_path(str(tmp_path / "koans" / "01_cart_test.py"), "cart.py") == PATH


def test_accepts_a_line_in_the_set(ask):
    assert ask("cart.py", 4, BUGGY, _sha(CART)) is None
    assert ask("cart.py", 3, BUGGY, _sha(CART)) is None


def test_accepts_fine_for_a_fine_file(ask):
    assert ask("cart.py", FINE, FINE_DIGESTS, _sha(CART)) is None


def test_says_has_a_bug_when_fine_on_a_buggy_file(ask):
    assert _refusal(ask, FINE, BUGGY) == (
        f"Not fine: {PATH} has a bug. Write the number of the line where it is."
    )


def test_says_it_is_fine_when_a_line_on_a_fine_file(ask):
    assert _refusal(ask, 4, FINE_DIGESTS) == f"Read {PATH} again: it is fine. Write FINE."


def test_says_not_that_line(ask):
    assert _refusal(ask, 2, BUGGY) == f"Not that line. Look again at {PATH}."


def test_wrong_line_on_an_edited_review_adds_the_moved_lines_note(ask, tmp_path):
    (tmp_path / PATH).write_text("\n" + CART)
    assert _refusal(ask, 2, BUGGY) == (
        f"Not that line. Look again at {PATH}.\n"
        f"{PATH} has changed since it was generated, so its line numbers may have moved: "
        f"git diff {PATH} shows how."
    )


def test_a_missing_review_counts_as_changed(ask, tmp_path):
    (tmp_path / PATH).unlink()
    assert _refusal(ask, 2, BUGGY).endswith(f"git diff {PATH} shows how.")


@pytest.mark.parametrize("answer", ["4", 0, -4, 4.0, True, False, None], ids=repr)
def test_refuses_a_string_zero_a_negative_a_float_and_a_bool_as_bad_shape(ask, answer):
    assert _refusal(ask, answer, BUGGY) == f"Write FINE, or a line number of {PATH} as an integer."


def test_a_verdict_blank_names_the_review_path(ask):
    with pytest.raises(Blank) as raised:
        ask("cart.py", __, BUGGY, _sha(CART))
    assert raised.value.kind == "verdict"
    assert raised.value.review_path == PATH
    assert str(raised.value) == f"Replace __ with FINE, or the number of the line with the bug in {PATH}."


def test_fine_reads_as_fine():
    assert repr(FINE) == "FINE"
