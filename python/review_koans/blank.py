from typing import Final, Literal, NoReturn

BlankKind = Literal["value", "code", "verdict"]

_MESSAGES: Final = {
    "value": "Replace __ with the value that makes this true.",
    "code": "Replace __() with the code the meditation describes.",
    "verdict": "Replace __ with FINE, or the number of the line with the bug in {path}.",
}


class Blank(Exception):
    def __init__(self, kind: BlankKind, review_path: str | None = None) -> None:
        super().__init__(_MESSAGES[kind].format(path=review_path))
        self.kind = kind
        self.review_path = review_path


def _value(*_args: object) -> NoReturn:
    raise Blank("value")


class _Blank:
    """Fails any koan that still contains it: comparing, hashing, testing or iterating raises."""

    __slots__ = ()

    __eq__ = __ne__ = __lt__ = __le__ = __gt__ = __ge__ = _value
    __hash__ = __bool__ = __iter__ = __len__ = __contains__ = __getitem__ = _value

    def __call__(self, *_args: object, **_kwargs: object) -> NoReturn:
        raise Blank("code")

    def __repr__(self) -> str:
        return "__"


__: Final = _Blank()
