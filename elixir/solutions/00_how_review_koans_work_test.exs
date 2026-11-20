defmodule Koans.Ch00.HowReviewKoansWorkTest do
  @moduledoc ~S"""
  Review koans come in three kinds, and each one fails until you answer it.

  - Predict: replace `__` with the value that makes the assertion true.
  - Review: read the module in `koans/review/`, then replace the `__` in its verdict with
    `:fine`, or with the number of the line that holds the bug. About one review in five is
    fine. After a bug, the next koan has you fix it in place, and hidden checks run your fix.
  - Trace: read a real crash captured in `traces/`, and name its cause and where it came from.

  `mix test` stops at the first koan that fails, and its footer says where to work. A blank:

      Meditate on koans/00_how_review_koans_work_test.exs:34

  A fix names the file to change and the koan that runs its checks. A failing check shows its
  label, never a raw value or the fix:

      A hidden case still fails: an ordinary discount
      ------------------------------- The master says --------------------------------
      Write:        koans/review/00_discount.ex
      Exercised by: koans/00_how_review_koans_work_test.exs:42
          Fix the bug in koans/review/00_discount.ex in place. The hidden checks name what still fails.
      2 of 128 koans answered.

  The checks are readable in `checks/`, as the answers are in `solutions/`. Read them only after
  a real attempt; reading them first defeats the exercise.

  A compile error stops the run before any footer: fix what the compiler names, then run
  `mix test` again. To start again, run `git checkout -- koans/`.
  """
  use Koans

  koan "A predict koan: the blank holds the value that makes the assertion true." do
    assert 40 + 2 == 42
  end

  koan "Read koans/review/00_discount.ex. Write :fine, or the line number of the bug." do
    verdict("00_discount.ex", 6, "3134d09144", "0a6594da56")
  end

  koan "Fix the bug in koans/review/00_discount.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch00.Discount, Review.Ch00.Discount)
  end

  koan "Read koans/review/00_cart_total.ex. Write :fine, or the line number of the bug." do
    verdict("00_cart_total.ex", :fine, "3a16cf444c", "3c31380555")
    run_checks(Checks.Ch00.CartTotal, Review.Ch00.CartTotal)
  end

  koan "Read traces/00_divide.exs.trace. Name the exception, then the file and line it came from." do
    assert Koans.Trace.exception("00_divide") == "ArithmeticError"
    assert Koans.Trace.first_frame("00_divide") == {"traces/00_divide.exs", 3}
  end
end
