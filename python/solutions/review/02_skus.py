"""Stock-keeping units. unique_skus returns each distinct SKU once."""

from dataclasses import dataclass


@dataclass(frozen=True)
class Sku:
    code: str
    size: str


def unique_skus(skus: list[Sku]) -> set[Sku]:
    return set(skus)
