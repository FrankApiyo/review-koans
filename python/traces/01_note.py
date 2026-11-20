from dataclasses import dataclass, field


@dataclass
class Note:
    title: str
    tags: list[str] = field(default=[])


print(Note("groceries"))
