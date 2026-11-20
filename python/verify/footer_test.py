from review_koans.footer import Failure, render, separator, total

MASTER = "-" * 31 + " The master says " + "-" * 32
ENLIGHTENMENT = "-" * 32 + " Enlightenment " + "-" * 33


def test_separator_is_80_columns_centred():
    assert separator("The master says") == MASTER
    assert separator("Enlightenment") == ENLIGHTENMENT
    assert len(MASTER) == len(ENLIGHTENMENT) == 80


def test_value_blank_footer():
    failure = Failure(
        path="koans/01_state_test.py",
        line=7,
        meditation="What does the second call return?",
        message="Replace __ with the value that makes this true.",
        write=None,
    )
    assert render(1, 3, 2, failure) == (
        "Replace __ with the value that makes this true.\n"
        f"{MASTER}\n"
        "Meditate on koans/01_state_test.py:7\n"
        "    What does the second call return?\n"
        "1 of 3 koans answered."
    )


def test_verdict_footer_indents_every_meditation_line():
    failure = Failure(
        path="koans/00_about_test.py",
        line=12,
        meditation="Read koans/review/00_discount.py.\nWrite FINE, or the line number of the bug.",
        message="Not that line. Look again at koans/review/00_discount.py.",
        write=None,
    )
    assert render(0, 4, 1, failure) == (
        "Not that line. Look again at koans/review/00_discount.py.\n"
        f"{MASTER}\n"
        "Meditate on koans/00_about_test.py:12\n"
        "    Read koans/review/00_discount.py.\n"
        "    Write FINE, or the line number of the bug.\n"
        "0 of 4 koans answered."
    )


def test_hidden_case_footer_names_the_file_to_write():
    failure = Failure(
        path="koans/01_state_test.py",
        line=20,
        meditation=(
            "Fix the bug in koans/review/01_make_config.py in place. "
            "The hidden checks name what still fails."
        ),
        message="A hidden case still fails: two configs share one list (it raised KeyError)",
        write="koans/review/01_make_config.py",
    )
    assert render(2, 5, 3, failure) == (
        "A hidden case still fails: two configs share one list (it raised KeyError)\n"
        f"{MASTER}\n"
        "Write:        koans/review/01_make_config.py\n"
        "Exercised by: koans/01_state_test.py:20\n"
        "    Fix the bug in koans/review/01_make_config.py in place. "
        "The hidden checks name what still fails.\n"
        "2 of 5 koans answered."
    )


def test_enlightenment_footer():
    assert render(3, 3, 3, None) == (
        f"{ENLIGHTENMENT}\nAll 3 koans pass. Start again with: git checkout -- koans/"
    )


def test_partial_footer():
    assert render(1, 3, 1, None) == "1 of 3 koans answered. Run the whole suite for the rest."


def test_a_run_with_no_koan_prints_no_footer():
    assert render(0, 3, 0, None) == ""


def test_total_counts_test_defs_in_numbered_koan_files_only(tmp_path):
    (tmp_path / "01_a_test.py").write_text("def test_a():\n    pass\n\n\ndef test_b():\n    pass\n")
    (tmp_path / "02_b_test.py").write_text("def test_c():\n    '''def test_not_at_line_start'''\n")
    (tmp_path / "helper_test.py").write_text("def test_d():\n    pass\n")
    (tmp_path / "review").mkdir()
    (tmp_path / "review" / "03_c_test.py").write_text("def test_e():\n    pass\n")
    assert total(tmp_path) == 3
