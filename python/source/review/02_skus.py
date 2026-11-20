"""Stock-keeping units. unique_skus returns each distinct SKU once."""

from dataclasses import dataclass


# >>> fix
@dataclass(eq=False)
# === fixed
@dataclass(frozen=True)
# === alt: frozen with slots
@dataclass(frozen=True, slots=True)
# === wrong: refuses — SKUs that cannot go in a set
@dataclass
# === wrong: partial — hashes the fields but compares by identity
@dataclass(eq=False, unsafe_hash=True)
# === wrong: partial — frozen but compares by identity
@dataclass(eq=False, frozen=True)
# === wrong: partial — a hash of fields that can still change
@dataclass(unsafe_hash=True)
# <<<
class Sku:
    code: str
    size: str


def unique_skus(skus: list[Sku]) -> set[Sku]:
    return set(skus)
