"""Notes search. search returns the lines of the file at path that contain pattern."""

import subprocess


def search(pattern: str, path: str, run=subprocess.run) -> list[str]:
    """Returns grep's matching lines for the fixed string pattern."""
    result = run(["grep", "-F", "--", pattern, path],
                 capture_output=True, text=True, check=False)
    return result.stdout.splitlines()
