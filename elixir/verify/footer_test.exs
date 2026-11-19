defmodule Verify.FooterTest do
  use ExUnit.Case, async: true

  alias Koans.Footer

  test "a value blank" do
    failure = %{
      path: "koans/01_reviews_test.exs",
      line: 9,
      meditation: "A price is a whole number of cents.",
      diff: "Replace __ with the value that makes this true.",
      write: nil
    }

    assert Footer.render(%{passed: 3, total: 40, ran: 4, failure: failure}) == """
           Replace __ with the value that makes this true.
           ------------------------------- The master says --------------------------------
           Meditate on koans/01_reviews_test.exs:9
               A price is a whole number of cents.
           3 of 40 koans answered.\
           """
  end

  test "a verdict message" do
    path = "koans/review/01_price_client.ex"

    failure = %{
      path: "koans/01_reviews_test.exs",
      line: 14,
      meditation: "Read #{path}.\nWrite :fine, or the line number of the bug.",
      diff:
        "Not that line. Look again at #{path}.\n" <>
          "#{path} has changed since it was generated, so its line numbers may have moved: " <>
          "git diff #{path} shows how.",
      write: nil
    }

    assert Footer.render(%{passed: 4, total: 40, ran: 5, failure: failure}) == """
           Not that line. Look again at koans/review/01_price_client.ex.
           koans/review/01_price_client.ex has changed since it was generated, so its line numbers may have moved: git diff koans/review/01_price_client.ex shows how.
           ------------------------------- The master says --------------------------------
           Meditate on koans/01_reviews_test.exs:14
               Read koans/review/01_price_client.ex.
               Write :fine, or the line number of the bug.
           4 of 40 koans answered.\
           """
  end

  test "a hidden case names the review file to write" do
    path = "koans/review/01_price_client.ex"

    failure = %{
      path: "koans/01_reviews_test.exs",
      line: 20,
      meditation: "Fix the bug in #{path} in place. The hidden checks name what still fails.",
      diff: "A hidden case still fails: a zero quantity is refused (it raised ArgumentError)",
      write: path
    }

    assert Footer.render(%{passed: 5, total: 40, ran: 6, failure: failure}) == """
           A hidden case still fails: a zero quantity is refused (it raised ArgumentError)
           ------------------------------- The master says --------------------------------
           Write:        koans/review/01_price_client.ex
           Exercised by: koans/01_reviews_test.exs:20
               Fix the bug in koans/review/01_price_client.ex in place. The hidden checks name what still fails.
           5 of 40 koans answered.\
           """
  end

  test "Enlightenment" do
    assert Footer.render(%{passed: 40, total: 40, ran: 40, failure: nil}) == """
           -------------------------------- Enlightenment ---------------------------------
           All 40 koans pass. Start again with: git checkout -- koans/\
           """
  end

  test "no koan at the line" do
    assert Footer.render(%{passed: 0, total: 40, ran: 0, failure: nil}) ==
             "No koan at that line: put the cursor inside a koan, or run the file."
  end

  test "a partial run" do
    assert Footer.render(%{passed: 6, total: 40, ran: 6, failure: nil}) ==
             "6 of 40 koans answered. Run the whole suite for the rest."
  end

  test "total counts koan lines across the chapter files" do
    assert Footer.total("verify/fixtures/two_files") == 4
    assert Footer.total("verify/fixtures/solved") == 3
  end

  test "kind names blanks, verdicts, timeouts, exits and other exceptions" do
    assert Footer.kind(:error, %Koans.Blank{}) == "Koans.Blank"
    assert Footer.kind(:error, %Koans.Verdict{}) == "Koans.Verdict"
    assert Footer.kind(:error, %ExUnit.TimeoutError{}) == "timeout"
    assert Footer.kind(:exit, :killed) == "exit"
    assert Footer.kind(:error, %ArgumentError{}) == "ArgumentError"
  end

  test "the earliest failure by file and line wins" do
    failures = [
      %{path: "b", line: 30, sort_key: {"/k/02_b_test.exs", 29}},
      %{path: "a", line: 41, sort_key: {"/k/01_a_test.exs", 40}},
      %{path: "c", line: 9, sort_key: {"/k/01_a_test.exs", 50}}
    ]

    for order <- [failures, Enum.reverse(failures)] do
      assert Footer.earliest(order) == %{path: "a", line: 41}
    end
  end
end
