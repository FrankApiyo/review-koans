"""A shopping cart that holds SKUs in the order they were added."""


class Cart:
    items = []

    def add(self, sku: str) -> None:
        self.items.append(sku)
