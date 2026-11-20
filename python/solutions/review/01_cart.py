"""A shopping cart that holds SKUs in the order they were added."""


class Cart:
    def __init__(self) -> None:
        self.items: list[str] = []

    def add(self, sku: str) -> None:
        self.items.append(sku)
