defmodule Koans.Fixture.HiddenArity.CartTest do
  use Koans

  koan "Fix the bug in verify/fixtures/hidden_arity/review/cart.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.HiddenArity.Cart, Review.HiddenArity.Cart)
  end
end
