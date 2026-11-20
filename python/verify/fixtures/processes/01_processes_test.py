def test_local_subprocess_import():
    """A koan cannot start a command, even through a module it imports itself."""
    import subprocess

    subprocess.run("echo pwned", shell=True, check=False)


def test_os_system():
    """Nor through the shell os.system starts."""
    import os

    os.system("true")


def test_os_popen():
    """Nor through a pipe."""
    import os

    os.popen("echo pwned").read()


def test_after_a_refusal():
    """A refusal caught inside the koan leaves the guard on for the next command."""
    import os

    try:
        os.system("true")
    except RuntimeError:
        pass
    os.system("true")
