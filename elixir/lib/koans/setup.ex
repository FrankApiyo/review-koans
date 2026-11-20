defmodule Koans.Setup do
  alias Support.Db

  @endpoint_config [
    secret_key_base: String.duplicate("review-koans-", 5) |> binary_part(0, 64),
    live_view: [signing_salt: "review-koans"],
    pubsub_server: Support.PubSub,
    render_errors: [formats: [html: Support.ErrorHTML], layout: false],
    server: false
  ]

  # A crash report that lands after its koan ends would print a check's input;
  # with capture_log on, no other log reaches the default handler. The handler goes only
  # once the database is up, so a failed connect still logs its cause.
  @spec start!() :: :ok
  def start! do
    warn_on_untested_runtime()
    put_env()
    Enum.each(Db.files(), &remove_stale!/1)

    {:ok, _} =
      Supervisor.start_link(
        [Support.Repo, {Phoenix.PubSub, name: Support.PubSub}, Support.Endpoint],
        strategy: :one_for_one,
        name: Support.Supervisor
      )

    :ok = Support.Migrations.run!()
    _ = :logger.remove_handler(:default)
    :ok
  end

  @tested_elixir "1.19"
  @tested_otp "28"

  @spec runtime_warning(String.t(), String.t()) :: String.t() | nil
  def runtime_warning(elixir_version, otp_release) do
    tested_elixir? = String.starts_with?(elixir_version, @tested_elixir <> ".")

    if tested_elixir? and otp_release == @tested_otp do
      nil
    else
      "Warning: this course is tested on Elixir #{@tested_elixir}.x and OTP #{@tested_otp}; " <>
        "you have Elixir #{elixir_version} and OTP #{otp_release}, so a result may differ."
    end
  end

  defp warn_on_untested_runtime do
    case runtime_warning(System.version(), System.otp_release()) do
      nil -> :ok
      line -> IO.puts(:stderr, line)
    end
  end

  defp remove_stale!(file) do
    case File.rm(file) do
      :ok -> :ok
      {:error, :enoent} -> :ok
      {:error, reason} -> raise File.Error, reason: reason, action: "remove", path: file
    end
  end

  defp put_env do
    Application.put_env(:phoenix, :json_library, Jason)

    Application.put_env(:review_koans, Support.Repo,
      database: Db.path(),
      pool_size: 1,
      log: false,
      telemetry_prefix: [:review_koans, :repo]
    )

    Application.put_env(:review_koans, Support.Endpoint, @endpoint_config)
  end

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
