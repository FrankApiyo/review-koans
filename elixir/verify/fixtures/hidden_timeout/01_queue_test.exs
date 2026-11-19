defmodule Koans.Fixture.HiddenTimeout.QueueTest do
  use Koans

  koan "Fix the bug in verify/fixtures/hidden_timeout/review/queue.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.HiddenTimeout.Queue, Review.HiddenTimeout.Queue)
  end
end
