defmodule Verify.VerdictTest do
  use ExUnit.Case, async: false

  alias Koans.Verdict

  @seed "verify/fixtures/verdicts/review/cart.ex"
  @source "04510edbdf"
  @buggy "886fdfa4ac,d5882bb7c9"
  @fine "dc2c050639"

  setup do
    dir =
      Path.join(System.tmp_dir!(), "review-koans-verdict-#{System.unique_integer([:positive])}")

    File.mkdir_p!(Path.join(dir, "review"))
    File.cp!(@seed, Path.join([dir, "review", "cart.ex"]))
    previous = System.get_env("KOANS_DIR")
    System.put_env("KOANS_DIR", dir)

    on_exit(fn ->
      restore_env("KOANS_DIR", previous)
      File.rm_rf!(dir)
    end)

    %{path: Path.join([dir, "review", "cart.ex"])}
  end

  defp restore_env(name, nil), do: System.delete_env(name)
  defp restore_env(name, value), do: System.put_env(name, value)

  defp message(answer, digests) do
    Verdict.check!("cart.ex", answer, digests, @source)
    flunk("expected Koans.Verdict for #{inspect(answer)}")
  rescue
    error in Verdict -> error.message
  end

  test "digest agrees with the generator's vectors" do
    assert Verdict.digest("cart.ex", 14) == "d5882bb7c9"
    assert Verdict.digest("cart.ex", 15) == "886fdfa4ac"
    assert Verdict.digest("cart.ex", :fine) == "dc2c050639"
  end

  test "the seed review file matches its source digest" do
    assert :crypto.hash(:sha256, File.read!(@seed)) |> Base.encode16(case: :lower) =~
             ~r/^#{@source}/
  end

  test "review_path joins KOANS_DIR, review and the file", %{path: path} do
    assert Verdict.review_path("cart.ex") == path
  end

  test "accepts a line in the set" do
    assert Verdict.check!("cart.ex", 14, @buggy, @source) == :ok
    assert Verdict.check!("cart.ex", 15, @buggy, @source) == :ok
  end

  test "accepts :fine for a fine file" do
    assert Verdict.check!("cart.ex", :fine, @fine, @source) == :ok
  end

  test "says has a bug when :fine on a buggy file", %{path: path} do
    assert message(:fine, @buggy) ==
             "Not fine: #{path} has a bug. Write the number of the line where it is."
  end

  test "says it is fine when a line on a fine file", %{path: path} do
    assert message(14, @fine) == "Read #{path} again: it is fine. Write :fine."
  end

  test "says not that line", %{path: path} do
    assert message(3, @buggy) == "Not that line. Look again at #{path}."
  end

  test "verdict on an edited review file adds the moved-lines note", %{path: path} do
    File.write!(path, "\n" <> File.read!(path))

    assert message(3, @buggy) ==
             "Not that line. Look again at #{path}.\n" <>
               "#{path} has changed since it was generated, so its line numbers may have moved: " <>
               "git diff #{path} shows how."
  end

  test "refuses a string, zero, a negative and a float as bad shape", %{path: path} do
    for answer <- ["14", 0, -1, 14.0] do
      assert message(answer, @buggy) ==
               "Write :fine, or a line number of #{path} as an integer."
    end
  end
end
