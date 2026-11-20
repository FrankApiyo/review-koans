import os
import subprocess
import sys

import pytest

from review_koans.offline import allow_processes
from verify.child import run_pytest

PROCESSES = "verify/fixtures/processes/01_processes_test.py"
PROCESS_KOANS = (1, 8, 15, 22)


def test_a_command_is_refused_inside_a_koan():
    done = run_pytest("verify/fixtures/processes", verify=True)
    tests = [line for line in done.stdout.splitlines() if line.startswith("KOANS-TEST")]
    assert tests == [f"KOANS-TEST RuntimeError {PROCESSES}:{line}" for line in PROCESS_KOANS]
    assert "RuntimeError: koans run no commands" in done.stdout


def test_commands_run_only_where_allowed():
    with pytest.raises(RuntimeError, match="koans run no commands"):
        subprocess.run([sys.executable, "-c", "pass"], check=True)
    with allow_processes():
        assert subprocess.run([sys.executable, "-c", "pass"], check=True).returncode == 0
    with pytest.raises(RuntimeError, match="koans run no commands"):
        os.system("true")


def test_the_guard_returns_after_an_exception():
    with pytest.raises(ZeroDivisionError), allow_processes():
        1 / 0
    with pytest.raises(RuntimeError, match="koans run no commands"):
        subprocess.run([sys.executable, "-c", "pass"], check=True)
