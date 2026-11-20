import json


def parse_order(body):
    try:
        return json.loads(body)
    except json.JSONDecodeError as error:
        raise ValueError(f"bad order at line {error.lineno}: {error.messg}")


parse_order('{"sku": "A1", "qty": }')
