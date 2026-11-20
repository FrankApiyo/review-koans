from dataclasses import dataclass
from decimal import Decimal

import pytest

from review_koans import __
from review_koans.blank import Blank

VALUE = "Replace __ with the value that makes this true."
CODE = "Replace __() with the code the meditation describes."


@dataclass(frozen=True)
class Point:
    x: int


OPERANDS = [42, "s", b"s", [1], (1,), {"a": 1}, {1}, None, True, Decimal("1"), float("nan"), Point(1)]


def _assert_value_blank(raised):
    assert raised.value.kind == "value"
    assert raised.value.review_path is None
    assert str(raised.value) == VALUE


@pytest.mark.parametrize("operand", OPERANDS, ids=repr)
def test_value_blank_raises_blank_against_every_operand(operand):
    with pytest.raises(Blank) as left:
        operand == __  # noqa: B015
    _assert_value_blank(left)
    with pytest.raises(Blank) as right:
        __ == operand  # noqa: B015
    _assert_value_blank(right)
    with pytest.raises(Blank) as unequal:
        operand != __  # noqa: B015
    _assert_value_blank(unequal)


USES = {
    "condition": lambda: 1 if __ else 0,
    "hash": lambda: hash(__),
    "set member": lambda: {__},
    "iteration": lambda: [item for item in __],
    "len": lambda: len(__),
    "contains": lambda: 1 in __,
    "in a list": lambda: __ in [1, 2],
    "index": lambda: __[0],
    "less than": lambda: __ < 1,
    "greater or equal": lambda: 1 >= __,
}


@pytest.mark.parametrize("use", USES.values(), ids=USES.keys())
def test_blank_in_a_condition_hash_or_iteration_raises(use):
    with pytest.raises(Blank) as raised:
        use()
    _assert_value_blank(raised)


def test_code_blank_call_raises_with_code_message():
    with pytest.raises(Blank) as raised:
        __()
    assert raised.value.kind == "code"
    assert str(raised.value) == CODE


def test_blank_reads_as_two_underscores():
    assert repr(__) == "__"
