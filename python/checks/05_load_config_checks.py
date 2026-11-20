import io

from review_koans.checks import exploit, raises, twin

PATH = "settings.json"


class Opener:
    def __init__(self, text):
        self.text = text
        self.handles = []

    def __call__(self, path, *args, **kwargs):
        assert path == PATH
        handle = io.StringIO(self.text)
        self.handles.append(handle)
        return handle

    def all_closed(self):
        return bool(self.handles) and all(handle.closed for handle in self.handles)


def valid(review):
    opener = Opener('{"debug": true, "port": 8000}')
    assert review.load_config(PATH, opener) == {"debug": True, "port": 8000}
    assert opener.all_closed()


def not_json(review):
    opener = Opener("{not json")
    with raises(ValueError):
        review.load_config(PATH, opener)
    assert opener.all_closed()


CASES = [
    twin("a valid settings file", valid),
    exploit("a settings file that is not valid JSON", not_json),
]
