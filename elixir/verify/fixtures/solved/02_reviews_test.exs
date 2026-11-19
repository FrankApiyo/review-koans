defmodule Koans.Fixture.Solved.ReviewsTest do
  use Koans

  koan "Read the cart. Write :fine, or the line number of the bug." do
    verdict("02_cart.ex", 2, "adb1a0084b", "4a489b17da")
  end
end
