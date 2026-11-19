defmodule Verify.RunTest do
  use ExUnit.Case, async: false

  @moduletag timeout: 120_000
  @build {"MIX_BUILD_PATH", "_build_variants"}

  setup_all do
    {out, status} =
      System.cmd("mix", ["compile"],
        env: [{"MIX_ENV", "test"}, {"KOANS_DIR", "verify/fixtures/solved"}, @build],
        stderr_to_stdout: true
      )

    assert status == 0, out
    :ok
  end

  defp run(fixture, args \\ [], env \\ []) do
    {out, status} =
      System.cmd("mix", ["test" | args],
        env: [{"KOANS_DIR", "verify/fixtures/#{fixture}"}, {"KOANS_VERIFY", nil}, @build | env],
        stderr_to_stdout: true
      )

    {String.replace(out, ~r/\e\[[0-9;]*m/, ""), status}
  end

  defp tail(out, count) do
    out |> String.trim_trailing() |> String.split("\n") |> Enum.take(-count) |> Enum.join("\n")
  end

  defp before_verify_lines(out) do
    out |> String.split("\nKOANS-TEST ", parts: 2) |> hd()
  end

  test "two files: the footer names the earlier file" do
    {out, _status} = run("two_files", [], [{"KOANS_VERIFY", "1"}])

    assert out =~ "KOANS-TEST Koans.Verdict verify/fixtures/two_files/02_second_test.exs:4"

    assert out |> before_verify_lines() |> tail(5) == """
           Replace __ with the value that makes this true.
           ------------------------------- The master says --------------------------------
           Meditate on verify/fixtures/two_files/01_first_test.exs:9
               A value blank stops the run.
           1 of 4 koans answered.\
           """
  end

  test "stops at the first failing koan" do
    {out, status} = run("two_files")

    assert status != 0
    refute out =~ "the later koan ran"

    assert tail(out, 5) == """
           Replace __ with the value that makes this true.
           ------------------------------- The master says --------------------------------
           Meditate on verify/fixtures/two_files/01_first_test.exs:9
               A value blank stops the run.
           1 of 4 koans answered.\
           """
  end

  test "single file" do
    {out, status} = run("solved", ["verify/fixtures/solved/01_values_test.exs"])

    assert status == 0
    assert tail(out, 1) == "2 of 3 koans answered. Run the whole suite for the rest."
  end

  test "file:line" do
    {out, status} = run("solved", ["verify/fixtures/solved/01_values_test.exs:8"])

    assert status == 0
    assert tail(out, 1) == "1 of 3 koans answered. Run the whole suite for the rest."
  end

  test "file:line above every koan" do
    {out, _status} = run("solved", ["verify/fixtures/solved/01_values_test.exs:1"])

    assert tail(out, 1) ==
             "No koan at that line: put the cursor inside a koan, or run the file."

    refute out =~ "koans answered"
  end

  test "solved fixture reaches Enlightenment" do
    {out, status} = run("solved")

    assert status == 0

    assert tail(out, 2) == """
           -------------------------------- Enlightenment ---------------------------------
           All 3 koans pass. Start again with: git checkout -- koans/\
           """
  end

  test "KOANS_VERIFY=1 prints one KOANS-TEST line per koan and a KOANS-RESULT" do
    {out, _status} = run("two_files", [], [{"KOANS_VERIFY", "1"}])

    assert out =~ "the later koan ran"

    assert tail(out, 5) == """
           KOANS-TEST ok verify/fixtures/two_files/01_first_test.exs:4
           KOANS-TEST Koans.Blank verify/fixtures/two_files/01_first_test.exs:8
           KOANS-TEST ExUnit.AssertionError verify/fixtures/two_files/01_first_test.exs:12
           KOANS-TEST Koans.Verdict verify/fixtures/two_files/02_second_test.exs:4
           KOANS-RESULT Koans.Blank verify/fixtures/two_files/01_first_test.exs:9\
           """
  end

  test "learner runs print no machine lines" do
    {out, _status} = run("solved")

    refute out =~ "KOANS-"
  end
end
