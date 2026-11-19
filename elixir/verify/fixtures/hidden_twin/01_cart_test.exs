defmodule Koans.Fixture.HiddenTwin.CartTest do
  use Koans

  koan "Fix the bug in verify/fixtures/hidden_twin/review/cart.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.HiddenTwin.Cart, Review.HiddenTwin.Cart)
  end
end
