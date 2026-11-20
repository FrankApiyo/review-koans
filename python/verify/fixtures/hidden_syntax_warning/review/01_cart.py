import re


def is_sku(text):
    """Returns whether text is a sku such as PEAR-7."""
    return re.fullmatch("[A-Z]+-\d+", text) is not None
