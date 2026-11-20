import os
import subprocess
import sys
from pathlib import Path

from review_koans.offline import allow_processes

PYTHON_DIR = Path(__file__).resolve().parent.parent
MASTER = "-" * 31 + " The master says " + "-" * 32
ENLIGHTENMENT = "-" * 32 + " Enlightenment " + "-" * 33
_INHERITED = ("KOANS_VERIFY", "PYTHONDONTWRITEBYTECODE", "PYTEST_ADDOPTS")


def run_pytest(*args: str, verify: bool = False) -> subprocess.CompletedProcess[str]:
    env = {key: value for key, value in os.environ.items() if key not in _INHERITED}
    if verify:
        env["KOANS_VERIFY"] = "1"
    with allow_processes():
        return subprocess.run(
            [sys.executable, "-m", "pytest", "--color=no", *args],
            cwd=PYTHON_DIR,
            env=env,
            capture_output=True,
            text=True,
            check=False,
            timeout=120,
        )
