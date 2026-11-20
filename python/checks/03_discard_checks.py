import os
import tempfile

from review_koans.checks import exploit, raises, twin


def existing(review):
    with tempfile.TemporaryDirectory() as folder:
        path = os.path.join(folder, "upload.tmp")
        with open(path, "w", encoding="utf-8") as file:
            file.write("x")
        review.discard(path)
        assert not os.path.exists(path)


def already_gone(review):
    with tempfile.TemporaryDirectory() as folder:
        path = os.path.join(folder, "upload.tmp")
        with open(path, "w", encoding="utf-8") as file:
            file.write("x")
        review.discard(path)
        review.discard(path)
        assert not os.path.exists(path)


def cannot_delete(review):
    with tempfile.TemporaryDirectory() as folder:
        path = os.path.join(folder, "uploads")
        os.mkdir(path)
        with raises(OSError):
            review.discard(path)
        assert os.path.isdir(path)


CASES = [
    twin("a file that exists", existing),
    twin("a file that is already gone", already_gone),
    exploit("a path that exists but cannot be deleted", cannot_delete),
]
