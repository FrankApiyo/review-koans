"""Notes search. search returns the lines of the file at path that contain pattern."""

import subprocess


def search(pattern: str, path: str, run=subprocess.run) -> list[str]:
    """Returns grep's matching lines for the fixed string pattern."""
    # >>> guard
    result = run(["grep", "-F", "--", pattern, path],
                 capture_output=True, text=True, check=False)
    return result.stdout.splitlines()
    # === wrong: partial — a shell string with quoted arguments
    import shlex

    command = f"grep -F -- {shlex.quote(pattern)} {shlex.quote(path)}"
    result = run(command, shell=True, capture_output=True, text=True, check=False)
    return result.stdout.splitlines()
    # === wrong: partial — a shell string
    result = run(f"grep -F {pattern} {path}", shell=True, capture_output=True, text=True, check=False)
    return result.stdout.splitlines()
    # <<<
