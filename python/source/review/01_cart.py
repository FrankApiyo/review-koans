"""A shopping cart that holds SKUs in the order they were added."""


class Cart:
    # >>> fix
    items = []
    # === fixed
    def __init__(self) -> None:
        self.items: list[str] = []
    # === wrong: refuses — a cart that cannot hold anything
    items: tuple[str, ...] = ()
    # === wrong: partial — a class attribute built with list()
    items: list[str] = list()
    # === wrong: partial — a class attribute declared as a plain list
    items: list = []
    # <<<

    def add(self, sku: str) -> None:
        self.items.append(sku)
