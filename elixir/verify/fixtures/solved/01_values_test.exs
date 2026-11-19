defmodule Koans.Fixture.Solved.ValuesTest do
  use Koans

  koan "Addition adds." do
    assert 1 + 1 == 2
  end

  koan "Lists keep their order." do
    assert [1, 2] == [1, 2]
  end
end
