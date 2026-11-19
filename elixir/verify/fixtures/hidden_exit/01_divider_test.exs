defmodule Koans.Fixture.HiddenExit.DividerTest do
  use Koans

  koan "Fix the bug in verify/fixtures/hidden_exit/review/divider.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.HiddenExit.Isolated, Review.HiddenExit.Divider)
  end

  koan "Fix the bug in verify/fixtures/hidden_exit/review/divider.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.HiddenExit.Unisolated, Review.HiddenExit.Divider)
  end
end
