import os
import subprocess

from review_koans.checks import exploit, twin

RUNNERS = (subprocess.run, subprocess.Popen, subprocess.call, subprocess.check_call, subprocess.check_output)


class Spy:
    def __init__(self, stdout=""):
        self.stdout = stdout
        self.calls = []

    def __call__(self, args, **kwargs):
        self.calls.append((args, kwargs))
        return subprocess.CompletedProcess(args, 0, stdout=self.stdout, stderr="")


class Proxy:
    def __init__(self, module, **replaced):
        self._module = module
        self.__dict__.update(replaced)

    def __getattr__(self, name):
        return getattr(self._module, name)


def no_command(*_args, **_kwargs):
    raise AssertionError


def block_commands(review):
    stand_ins = {
        subprocess: Proxy(subprocess, **{name: no_command for name in ("run", "Popen", "call", "check_call", "check_output")}),
        os: Proxy(os, system=no_command, popen=no_command),
        os.system: no_command,
        os.popen: no_command,
        **{runner: no_command for runner in RUNNERS},
    }
    for name, value in list(vars(review).items()):
        for real, stand_in in stand_ins.items():
            if value is real:
                setattr(review, name, stand_in)


def argv_for(review, pattern):
    block_commands(review)
    spy = Spy()
    review.search(pattern, "notes.txt", run=spy)
    [(args, kwargs)] = spy.calls
    assert not kwargs.get("shell")
    assert isinstance(args, (list, tuple))
    assert pattern in args
    assert args[args.index(pattern) - 1] in ("--", "-e")
    assert args[-1] == "notes.txt"


def plain(review):
    block_commands(review)
    spy = Spy("buy milk\nbuy eggs\n")
    assert review.search("buy", "notes.txt", run=spy) == ["buy milk", "buy eggs"]
    assert len(spy.calls) == 1


def shell_syntax(review):
    argv_for(review, "x; touch pwned")


def dash(review):
    argv_for(review, "-r")


CASES = [
    twin("a plain pattern", plain),
    exploit("a pattern with shell syntax in it", shell_syntax),
    exploit("a pattern that starts with a dash", dash),
]
