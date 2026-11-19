defmodule ReviewKoans.MixProject do
  use Mix.Project

  def project do
    dir = koans_dir()

    [
      app: :review_koans,
      version: "0.1.0",
      elixir: "~> 1.19",
      elixirc_paths: ["lib", "checks", Path.join(dir, "review")],
      consolidate_protocols: false,
      test_paths: [dir],
      test_pattern: "*_test.exs",
      test_load_filters: [&(String.ends_with?(&1, "_test.exs") and not nested?(&1))],
      test_ignore_filters: [&nested?/1],
      aliases: [test: "test --max-requires 1"],
      deps: deps()
    ]
  end

  def application, do: [extra_applications: [:logger, :crypto]]

  defp deps do
    [
      {:ecto_sql, "~> 3.14"},
      {:ecto_sqlite3, "~> 0.26"},
      {:phoenix, "~> 1.8"},
      {:phoenix_live_view, "~> 1.1"},
      {:jason, "~> 1.4"},
      {:lazy_html, "~> 0.1", only: :test}
    ]
  end

  defp koans_dir, do: System.get_env("KOANS_DIR", "koans")

  # Review modules and fixture koans below the test dir are compiled or run only on purpose.
  defp nested?(path) do
    path
    |> Path.relative_to(koans_dir())
    |> String.starts_with?(["review/", "fixtures/"])
  end
end
