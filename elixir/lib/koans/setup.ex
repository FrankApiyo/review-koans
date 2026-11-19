defmodule Koans.Setup do
  @spec start!() :: :ok
  def start!, do: :ok

  @spec ex_unit_options() :: keyword()
  def ex_unit_options do
    base = [
      seed: 0,
      timeout: 5_000,
      capture_log: true,
      max_cases: 1,
      formatters: [Koans.Formatter]
    ]

    if verify?(), do: base, else: base ++ [max_failures: 1]
  end

  @spec verify?() :: boolean()
  def verify?, do: System.get_env("KOANS_VERIFY") == "1"
end
