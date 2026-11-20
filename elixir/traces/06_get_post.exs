# needs: deps
defmodule Blog do
  import Ecto.Query

  alias Course.Ch06.Post
  alias Support.Repo

  def get_post!(user, id) do
    Repo.one!(from p in Post, where: p.id == ^id and p.user_id == ^user.id)
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

alias Course.Ch06.{Post, User}
alias Support.Repo

{:ok, default} = :logger.get_handler_config(:default)
:ok = Koans.Setup.start!()

:ok =
  :logger.add_handler(:printed, Printed, %{
    formatter: default.formatter,
    config: %{script: self()}
  })

ada = Repo.insert!(%User{email: "ada@example.com"})
bob = Repo.insert!(%User{email: "bob@example.com"})
post = Repo.insert!(%Post{user_id: ada.id, title: "Ada's draft"})
{reader, ref} = spawn_monitor(Blog, :get_post!, [bob, post.id])

receive do
  {:DOWN, ^ref, :process, ^reader, _reason} -> :ok
end

receive do
  :printed -> :ok
end
