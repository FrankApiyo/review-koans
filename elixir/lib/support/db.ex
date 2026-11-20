defmodule Support.Db do
  @moduledoc """
  The course database: a file in the build directory, so a reconnect after a client dies
  mid-transaction reopens the same schema.
  """

  alias Support.Repo

  @course_tables """
  SELECT name FROM pragma_table_list
  WHERE schema = 'main' AND type IN ('table', 'virtual')
    AND name NOT LIKE 'sqlite_%' AND name <> 'schema_migrations'
  ORDER BY name
  """

  @spec path() :: String.t()
  def path, do: Path.join(Mix.Project.build_path(), "review_koans.sqlite3")

  @doc "The database file and the journal files SQLite keeps beside it."
  @spec files() :: [String.t()]
  def files, do: [path() | Enum.map(["-wal", "-shm", "-journal"], &(path() <> &1))]

  @doc "Deletes every row of every course table and restarts their ids at 1."
  @spec reset!() :: :ok
  def reset! do
    {:ok, :ok} = Repo.transaction(&delete_rows/0)
    :ok
  end

  defp delete_rows do
    Repo.query!("PRAGMA defer_foreign_keys = ON")
    Enum.each(Repo.query!(@course_tables).rows, fn [table] -> delete_all(table) end)
    if sequence?(), do: delete_all("sqlite_sequence")
    :ok
  end

  defp delete_all(table), do: Repo.query!(~s(DELETE FROM "#{table}"))

  defp sequence? do
    Repo.query!("SELECT 1 FROM sqlite_master WHERE name = 'sqlite_sequence'").num_rows == 1
  end
end
