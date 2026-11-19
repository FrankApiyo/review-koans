defmodule Koans.Fixture.TwoFiles.SecondTest do
  use Koans

  koan "Read the cart. Write :fine, or the line number of the bug." do
    verdict("02_cart.ex", 3, "adb1a0084b", "c5d8d1efa0")
  end
end
