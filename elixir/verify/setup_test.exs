defmodule Verify.SetupTest do
  use ExUnit.Case, async: false

  @moduletag timeout: 120_000

  setup do
    build =
      Path.join(System.tmp_dir!(), "review_koans_setup_#{System.unique_integer([:positive])}")

    File.mkdir_p!(build)
    File.ln_s!(Path.join(Mix.Project.build_path(), "lib"), Path.join(build, "lib"))

    on_exit(fn ->
      File.chmod!(build, 0o755)
      File.rm_rf!(build)
    end)

    [build: build]
  end

  defp start_in(build) do
    System.cmd("mix", ["run", "--no-compile", "-e", "Koans.Setup.start!()"],
      env: [{"MIX_ENV", "test"}, {"KOANS_DIR", "verify"}, {"MIX_BUILD_PATH", build}],
      stderr_to_stdout: true
    )
  end

  test "the runtime warning names the tested versions and stays quiet on them" do
    assert Koans.Setup.runtime_warning("1.19.5", "28") == nil
    assert Koans.Setup.runtime_warning("1.19.0", "28") == nil

    for {elixir, otp} <- [{"1.20.0", "28"}, {"1.18.4", "28"}, {"1.19.5", "29"}, {"1.190.0", "28"}] do
      line = Koans.Setup.runtime_warning(elixir, otp)
      assert line =~ "Warning: this course is tested on Elixir 1.19.x and OTP 28"
      assert line =~ "Elixir #{elixir} and OTP #{otp}"
      refute line =~ "\n"
    end
  end

  test "a stale database file that cannot be removed stops startup with its path", %{build: build} do
    File.mkdir_p!(Path.join([build, "review_koans.sqlite3", "kept"]))

    {out, status} = start_in(build)

    assert status != 0
    assert out =~ "** (File.Error)"
    assert out =~ "review_koans.sqlite3"
  end

  test "a database that cannot be opened logs why before startup fails", %{build: build} do
    File.chmod!(build, 0o555)

    {out, status} = start_in(build)

    assert status != 0
    assert out =~ "Exqlite.Error"
  end
end
