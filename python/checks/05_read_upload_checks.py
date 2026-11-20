import os
import tempfile
from contextlib import contextmanager
from pathlib import Path

from review_koans.checks import exploit, raises, twin


@contextmanager
def uploads():
    with tempfile.TemporaryDirectory() as folder:
        root = Path(os.path.realpath(folder))
        (root / "files" / "notes").mkdir(parents=True)
        (root / "files" / "notes" / "a.txt").write_text("hello", encoding="utf-8")
        (root / "files" / "v1..final.txt").write_text("dots", encoding="utf-8")
        (root / "files-private").mkdir()
        (root / "files-private" / "key").write_text("key", encoding="utf-8")
        (root / "secret.txt").write_text("secret", encoding="utf-8")
        yield root


def refused(review, root, *names):
    for name in names:
        with raises(PermissionError):
            review.read_upload(str(root / "files"), name)


def subfolder(review):
    with uploads() as root:
        assert review.read_upload(str(root / "files"), "notes/a.txt") == "hello"


def two_dots(review):
    with uploads() as root:
        assert review.read_upload(str(root / "files"), "v1..final.txt") == "dots"


def climbs_out(review):
    with uploads() as root:
        refused(review, root, "../secret.txt", "notes/../../secret.txt")


def absolute(review):
    with uploads() as root:
        refused(review, root, str(root / "secret.txt"))


def neighbour(review):
    with uploads() as root:
        refused(review, root, "../files-private/key")


CASES = [
    twin("a file in a subfolder", subfolder),
    twin("a file name with two dots in a row", two_dots),
    exploit("a name that climbs out of the folder", climbs_out),
    exploit("an absolute path", absolute),
    exploit("a name that reaches a neighbouring folder", neighbour),
]
