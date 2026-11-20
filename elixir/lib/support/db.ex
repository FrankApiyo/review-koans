defmodule Support.Db do
  @moduledoc """
  The course database: a file in the build directory, so a reconnect after a client dies
  mid-transaction reopens the same schema.
  """

  alias Support.Repo

  @course_tables """
  SELECT l.name, l.type, m.sql FROM pragma_table_list AS l
  JOIN sqlite_master AS m ON m.name = l.name
  WHERE l.schema = 'main' AND l.type IN ('table', 'virtual')
    AND l.name NOT LIKE 'sqlite_%' AND l.name <> 'schema_migrations'
  ORDER BY l.name
  """

  # An FTS5 table declared with content= keeps no rows of its own: DELETE FROM it is refused
  # (contentless) or reads the content table (external content), so its index is cleared instead,
  # after every ordinary table, since a content table's delete trigger needs the full index.
  @fts5_content ~r/\busing\s+fts5\b.*\bcontent\s*=/is

  @spec path() :: String.t()
  def path, do: Path.join(Mix.Project.build_path(), "review_koans.sqlite3")

  @doc "The database file and the journal files SQLite keeps beside it."
  @spec files() :: [String.t()]
  def files, do: [path() | Enum.map(["-wal", "-shm", "-journal"], &(path() <> &1))]

  @doc "Deletes every row of every course table and restarts their ids at 1."
  @spec reset!() :: :ok
  def reset! do
    {:ok, :ok} = Repo.transact(&delete_rows/0)
    :ok
  end

  defp delete_rows do
    Repo.query!("PRAGMA defer_foreign_keys = ON")

    Repo.query!(@course_tables).rows
    |> Enum.sort_by(&index_only?/1)
    |> Enum.each(&clear/1)

    if sequence?(), do: delete_all("sqlite_sequence")
    {:ok, :ok}
  end

  defp index_only?([_table, type, sql]),
    do: type == "virtual" and Regex.match?(@fts5_content, sql)

  defp clear([table, _type, _sql] = row) do
    if index_only?(row),
      do: Repo.query!(~s|INSERT INTO "#{table}"("#{table}") VALUES ('delete-all')|),
      else: delete_all(table)
  end

  defp delete_all(table), do: Repo.query!(~s(DELETE FROM "#{table}"))

  defp sequence? do
    Repo.query!("SELECT 1 FROM sqlite_master WHERE name = 'sqlite_sequence'").num_rows == 1
  end
end
