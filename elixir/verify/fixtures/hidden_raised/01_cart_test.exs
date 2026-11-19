defmodule Koans.Fixture.HiddenRaised.CartTest do
  use Koans

  koan "Fix the bug in verify/fixtures/hidden_raised/review/cart.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.HiddenRaised.Cart, Review.HiddenRaised.Cart)
  end
end
