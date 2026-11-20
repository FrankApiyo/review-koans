defmodule Support.Migrations do
  alias Support.Repo

  @migrations []

  @spec run!() :: :ok
  def run! do
    _ = Ecto.Migrator.run(Repo, @migrations, :up, all: true, log: false)
    :ok
  end
end
