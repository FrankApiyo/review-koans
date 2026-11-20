# needs: deps
defmodule Accounts do
  import Ecto.Changeset

  alias Course.Ch06.User
  alias Support.Repo

  def register(email) do
    changeset = %User{} |> cast(%{email: email}, [:email]) |> validate_required([:email])
    {:ok, user} = Repo.insert(changeset)
    user
  end
end

# The logger can print a report after the script has exited. This handler prints each report
# as the default handler would, then tells the script, so every run prints the same output.
defmodule Printed do
  def log(event, %{formatter: {formatter, options}, config: %{script: script}}) do
    IO.write(formatter.format(event, options))
    send(script, :printed)
  end
end

{:ok, default} = :logger.get_handler_config(:default)
:ok = Koans.Setup.start!()

:ok =
  :logger.add_handler(:printed, Printed, %{
    formatter: default.formatter,
    config: %{script: self()}
  })

%{email: "ada@example.com"} = Accounts.register("ada@example.com")
{signup, ref} = spawn_monitor(Accounts, :register, ["ada@example.com"])

receive do
  {:DOWN, ^ref, :process, ^signup, _reason} -> :ok
end

receive do
  :printed -> :ok
end
