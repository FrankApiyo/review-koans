defmodule Verify.HiddenTest do
  use ExUnit.Case, async: false

  alias Koans.Hidden
  alias Koans.HiddenCase

  @moduletag timeout: 120_000
  @build {"MIX_BUILD_PATH", "_build_variants"}
  @separator "------------------------------- The master says --------------------------------"

  defmodule PassingChecks do
    @behaviour Koans.Checks

    @impl true
    def cases do
      parent = self()
      [{:exploit, "first", fn -> send(parent, :first) end}, {:twin, "second", fn -> :ok end}]
    end
  end

  defmodule ThrowingChecks do
    @behaviour Koans.Checks

    @impl true
    def cases do
      parent = self()

      [
        {:exploit, "first", fn -> send(parent, :first) end},
        {:twin, "a thrown value", fn -> throw(:secret_input_2209) end},
        {:exploit, "third", fn -> send(parent, :third) end}
      ]
    end
  end

  defmodule ExitingChecks do
    @behaviour Koans.Checks

    @impl true
    def cases, do: [{:exploit, "an exit", fn -> exit(:secret_input_2209) end}]
  end

  defp run(fixture, args, env) do
    {out, status} =
      System.cmd("mix", ["test" | args],
        env: [{"KOANS_DIR", "verify/fixtures/#{fixture}"}, {"KOANS_VERIFY", nil}, @build | env],
        stderr_to_stdout: true
      )

    {String.replace(out, ~r/\e\[[0-9;]*m/, ""), status}
  end

  defp run_verify(fixture), do: run(fixture, [], [{"KOANS_VERIFY", "1"}])

  defp footer(out, count) do
    out
    |> String.split("\nKOANS-TEST ", parts: 2)
    |> hd()
    |> String.trim_trailing()
    |> String.split("\n")
    |> Enum.take(-count)
    |> Enum.join("\n")
  end

  defp meditation(review),
    do: "    Fix the bug in #{review} in place. The hidden checks name what still fails."

  defp refute_leaks(out, literal) do
    refute out =~ literal
    refute out =~ "assert"
    refute out =~ "left:"
  end

  test "exploit failure shows label only" do
    {out, status} = run_verify("hidden_exploit")
    review = "verify/fixtures/hidden_exploit/review/cart.ex"

    assert status != 0

    assert footer(out, 6) ==
             Enum.join(
               [
                 "A hidden case still fails: an empty add",
                 @separator,
                 "Write:        #{review}",
                 "Exercised by: verify/fixtures/hidden_exploit/01_cart_test.exs:5",
                 meditation(review),
                 "0 of 1 koans answered."
               ],
               "\n"
             )

    assert out =~
             "KOANS-TEST Koans.HiddenCase:exploit verify/fixtures/hidden_exploit/01_cart_test.exs:4"

    refute_leaks(out, "pear_7731")
  end

  test "twin failure is reported as twin" do
    {out, _status} = run_verify("hidden_twin")

    assert out =~
             "KOANS-TEST Koans.HiddenCase:twin verify/fixtures/hidden_twin/01_cart_test.exs:4"

    assert String.starts_with?(
             footer(out, 6),
             "A hidden case still fails: a positive add\n" <> @separator
           )

    refute_leaks(out, "plum_4417")
  end

  test "a raise in the learner's code names the exception module only" do
    {out, _status} = run_verify("hidden_raised")

    assert footer(out, 6) |> String.split("\n") |> hd() ==
             "A hidden case still fails: a line with no qty counts once (it raised KeyError)"

    assert out =~
             "KOANS-TEST Koans.HiddenCase:exploit verify/fixtures/hidden_raised/01_cart_test.exs:4"

    refute_leaks(out, "9907")
    refute out =~ ":qty"
  end

  test "a linked crash inside isolated is a hidden case, and an unisolated one gives the exit text" do
    file = "verify/fixtures/hidden_exit/01_divider_test.exs"
    review = "verify/fixtures/hidden_exit/review/divider.ex"
    {out, _status} = run_verify("hidden_exit")

    assert out =~ "KOANS-TEST Koans.HiddenCase:exploit #{file}:4\nKOANS-TEST exit #{file}:8\n"

    assert String.starts_with?(
             footer(out, 6),
             "A hidden case still fails: no parts\n" <> @separator
           )

    refute_leaks(out, "6413")

    {out, _status} = run("hidden_exit", ["#{file}:8"], [])

    assert footer(out, 6) ==
             Enum.join(
               [
                 "A hidden case stopped the koan: the test process exited.",
                 @separator,
                 "Write:        #{review}",
                 "Exercised by: #{file}:8",
                 meditation(review),
                 "0 of 2 koans answered."
               ],
               "\n"
             )

    refute_leaks(out, "6413")
  end

  test "a fix koan that hangs past 5 s gives the timeout text with Write:" do
    file = "verify/fixtures/hidden_timeout/01_queue_test.exs"
    review = "verify/fixtures/hidden_timeout/review/queue.ex"
    {out, _status} = run_verify("hidden_timeout")

    assert footer(out, 6) ==
             Enum.join(
               [
                 "A hidden case did not finish within 5 seconds.",
                 @separator,
                 "Write:        #{review}",
                 "Exercised by: #{file}:4",
                 meditation(review),
                 "0 of 1 koans answered."
               ],
               "\n"
             )

    assert out =~ "KOANS-TEST timeout #{file}:4"
    refute_leaks(out, "empty_5531")
  end

  test "run_checks returns :ok when every case passes, in list order" do
    assert Hidden.run_checks(PassingChecks, __MODULE__) == :ok
    assert_received :first
  end

  test "run_checks stops at the first failure and reports a throw as an exit" do
    error = assert_raise HiddenCase, fn -> Hidden.run_checks(ThrowingChecks, __MODULE__) end

    assert_received :first
    refute_received :third

    assert error == %HiddenCase{
             label: "a thrown value",
             kind: :twin,
             review_path: "verify/hidden_test.exs",
             cause: :exited
           }

    assert Exception.message(error) == "A hidden case still fails: a thrown value (it exited)"
  end

  test "run_checks reports an exit by label only" do
    error = assert_raise HiddenCase, fn -> Hidden.run_checks(ExitingChecks, __MODULE__) end

    assert error.cause == :exited
    refute Exception.message(error) =~ "secret_input_2209"
  end

  test "hidden case messages carry the frozen suffixes" do
    base = %HiddenCase{label: "an empty add", kind: :exploit, review_path: "r.ex"}

    assert Exception.message(base) == "A hidden case still fails: an empty add"

    assert Exception.message(%{base | cause: {:raised, KeyError}}) ==
             "A hidden case still fails: an empty add (it raised KeyError)"

    assert Exception.message(%{base | cause: :exited}) ==
             "A hidden case still fails: an empty add (it exited)"
  end

  test "isolated returns {:ok, v}, {:down, reason} and :timeout" do
    parent = self()

    assert Hidden.isolated(fn -> :done end) == {:ok, :done}
    assert Hidden.isolated(fn -> exit(:boom) end) == {:down, :boom}

    linked_crash = fn ->
      spawn_link(fn -> exit(:linked) end)
      receive(do: (:never -> :ok))
    end

    assert Hidden.isolated(linked_crash) == {:down, :linked}

    hang = fn ->
      send(parent, {:hung, self()})
      receive(do: (:never -> :ok))
    end

    assert Hidden.isolated(hang, 10) == :timeout
    assert_received {:hung, pid}
    refute Process.alive?(pid)
    refute_received {:DOWN, _, _, _, _}
  end

  test "wait_until gives up after its tries" do
    tries = :counters.new(1, [])
    count = fn -> :counters.add(tries, 1, 1) end

    refute Hidden.wait_until(fn -> count.() && false end, 5)
    assert :counters.get(tries, 1) == 5

    assert Hidden.wait_until(fn -> count.() && :counters.get(tries, 1) >= 8 end, 5)
    assert :counters.get(tries, 1) == 8
  end

  test "Footer.kind names hidden cases and process exits" do
    assert Koans.Footer.kind(:error, %HiddenCase{kind: :exploit}) == "Koans.HiddenCase:exploit"
    assert Koans.Footer.kind(:error, %HiddenCase{kind: :twin}) == "Koans.HiddenCase:twin"
    assert Koans.Footer.kind({:EXIT, self()}, :killed) == "exit"
  end
end
