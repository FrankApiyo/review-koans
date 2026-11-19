defmodule Koans.Fixture.TwoFiles.FirstTest do
  use Koans

  koan "Addition adds." do
    assert 1 + 1 == 2
  end

  koan "A value blank stops the run." do
    assert 1 + 1 == __
  end

  koan "A later koan in the same file." do
    IO.puts("the later koan ran")
    assert 1 + 1 == 3
  end
end
