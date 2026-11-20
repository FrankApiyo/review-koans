from verify.child import ENLIGHTENMENT, MASTER, PYTHON_DIR, run_pytest

VERDICTS = "verify/fixtures/verdicts/01_verdicts_test.py"
FIRST = "verify/fixtures/two_files/01_first_test.py"
SECOND = "verify/fixtures/two_files/02_second_test.py"
ALPHA = "verify/fixtures/single_file/01_alpha_test.py"
VALUE = "Replace __ with the value that makes this true."


def test_two_files_footer_names_the_earlier_file():
    footer = f"{VALUE}\n{MASTER}\nMeditate on {FIRST}:11\n    What is two?\n1 of 3 koans answered."
    default = run_pytest("verify/fixtures/two_files")
    assert default.returncode == 1
    assert footer in default.stdout
    reversed_order = run_pytest(SECOND, FIRST, verify=True)
    assert "2 failed, 1 passed" in reversed_order.stdout
    assert footer in reversed_order.stdout
    assert f"KOANS-RESULT Blank {FIRST}:11" in reversed_order.stdout


def test_stops_at_the_first_failing_koan():
    done = run_pytest("verify/fixtures/verdicts")
    assert done.returncode == 1
    assert "1 failed, 1 passed" in done.stdout
    assert "test_value_blank" not in done.stdout
    assert (
        "Read verify/fixtures/verdicts/review/fine.py again: it is fine. Write FINE.\n"
        f"{MASTER}\n"
        f"Meditate on {VERDICTS}:11\n"
        "    Read verify/fixtures/verdicts/review/fine.py. Write FINE, or the line number of the bug.\n"
        "1 of 4 koans answered.\n"
    ) in done.stdout


def test_single_file():
    done = run_pytest(ALPHA)
    assert done.returncode == 0
    assert "\n2 of 3 koans answered. Run the whole suite for the rest.\n" in done.stdout
    assert MASTER not in done.stdout


def test_single_koan():
    done = run_pytest(f"{ALPHA}::test_two")
    assert done.returncode == 0
    assert "1 passed" in done.stdout
    assert "\n1 of 3 koans answered. Run the whole suite for the rest.\n" in done.stdout


def test_solved_fixture_reaches_enlightenment():
    done = run_pytest("verify/fixtures/solved")
    assert done.returncode == 0
    assert f"\n{ENLIGHTENMENT}\nAll 3 koans pass. Start again with: git checkout -- koans/\n" in done.stdout


def test_verify_mode_prints_one_koans_test_line_per_koan_and_a_result():
    done = run_pytest("verify/fixtures/verdicts", verify=True)
    assert "3 failed, 1 passed" in done.stdout
    lines = [line for line in done.stdout.splitlines() if line.startswith("KOANS-")]
    assert lines == [
        f"KOANS-TEST ok {VERDICTS}:4",
        f"KOANS-TEST Verdict {VERDICTS}:9",
        f"KOANS-TEST Blank {VERDICTS}:14",
        f"KOANS-TEST Blank {VERDICTS}:20",
        f"KOANS-RESULT Verdict {VERDICTS}:11",
    ]


def test_a_value_blank_fails_on_its_own_line():
    done = run_pytest(f"{VERDICTS}::test_value_blank", verify=True)
    assert f"KOANS-TEST Blank {VERDICTS}:14" in done.stdout
    assert f"KOANS-RESULT Blank {VERDICTS}:17" in done.stdout
    assert f"{VALUE}\n{MASTER}\nMeditate on {VERDICTS}:17\n" in done.stdout


def test_a_verdict_blank_names_the_koan_not_the_review():
    done = run_pytest(f"{VERDICTS}::test_blank_verdict")
    assert (
        "Replace __ with FINE, or the number of the line with the bug in "
        "verify/fixtures/verdicts/review/cart.py.\n"
        f"{MASTER}\n"
        f"Meditate on {VERDICTS}:22\n"
    ) in done.stdout


def test_no_pycache_is_written_under_koans():
    solved = PYTHON_DIR / "verify" / "fixtures" / "solved"

    def compiled():
        return sorted(str(path) for path in solved.rglob("*") if path.name == "__pycache__" or path.suffix == ".pyc")

    assert compiled() == []
    done = run_pytest("verify/fixtures/solved")
    assert done.returncode == 0
    assert compiled() == []


def test_a_skipped_or_expected_failure_koan_is_not_a_failure():
    done = run_pytest("verify/fixtures/skips", verify=True)
    skips = "verify/fixtures/skips/01_skips_test.py"
    lines = [line for line in done.stdout.splitlines() if line.startswith("KOANS-")]
    assert lines == [f"KOANS-TEST ok {skips}:4", "KOANS-RESULT ok"]
    assert MASTER not in done.stdout


def test_a_blank_in_a_helper_fails_on_the_helper_line():
    helper = "verify/fixtures/helper/01_helper_test.py"
    done = run_pytest("verify/fixtures/helper", verify=True)
    assert f"KOANS-RESULT Blank {helper}:5" in done.stdout
    assert f"Meditate on {helper}:5\n" in done.stdout


def test_verify_mode_reports_a_syntax_error_as_a_collection_error():
    done = run_pytest("verify/fixtures/syntax_error", verify=True)
    assert done.returncode != 0
    assert "KOANS-RESULT CollectionError verify/fixtures/syntax_error/01_broken_test.py:6" in done.stdout
    assert "KOANS-RESULT ok" not in done.stdout


def test_verify_mode_reports_a_failed_import_as_a_collection_error():
    done = run_pytest("verify/fixtures/import_error", verify=True)
    assert done.returncode != 0
    assert "KOANS-RESULT CollectionError verify/fixtures/import_error/01_missing_test.py:3" in done.stdout
    assert "KOANS-RESULT ok" not in done.stdout
