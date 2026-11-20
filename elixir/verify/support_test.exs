defmodule Verify.SupportTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Support.Db
  alias Support.Repo

  @endpoint Support.Endpoint
  @query_event [:review_koans, :repo, :query]

  defmodule Migration do
    use Ecto.Migration

    def change do
      create table(:verify_owners) do
        add :name, :string, null: false
      end

      create table(:verify_pens) do
        add :label, :string, null: false
        add :owner_id, references(:verify_owners), null: false
      end

      execute "CREATE VIRTUAL TABLE verify_words USING fts5(word)", "DROP TABLE verify_words"

      execute "CREATE VIRTUAL TABLE verify_owner_index USING fts5(name, content='verify_owners', content_rowid='id')",
              "DROP TABLE verify_owner_index"

      execute "CREATE VIRTUAL TABLE verify_tokens USING fts5(word, content='')",
              "DROP TABLE verify_tokens"

      create table(:verify_labels) do
        add :label, :string, null: false
      end

      execute "CREATE VIRTUAL TABLE fts_verify_labels USING fts5(label, content='verify_labels', content_rowid='id')",
              "DROP TABLE fts_verify_labels"

      execute """
              CREATE TRIGGER verify_labels_insert AFTER INSERT ON verify_labels BEGIN
                INSERT INTO fts_verify_labels(rowid, label) VALUES (new.id, new.label);
              END
              """,
              "DROP TRIGGER verify_labels_insert"

      execute """
              CREATE TRIGGER verify_labels_delete AFTER DELETE ON verify_labels BEGIN
                INSERT INTO fts_verify_labels(fts_verify_labels, rowid, label)
                VALUES ('delete', old.id, old.label);
              END
              """,
              "DROP TRIGGER verify_labels_delete"
    end
  end

  defmodule SessionLive do
    use Phoenix.LiveView

    def mount(_params, %{"uid" => uid}, socket), do: {:ok, assign(socket, uid: uid)}

    def render(assigns), do: ~H|<p id="uid">{@uid}</p>|
  end

  setup_all do
    stale = "left by an earlier run"
    File.write!(Db.path(), stale)
    File.write!(Db.path() <> "-wal", stale)
    :ok = Koans.Setup.start!()
    [_ | _] = Ecto.Migrator.run(Repo, [{1, Migration}], :up, all: true, log: false)
    :ok
  end

  setup do
    :ok = Db.reset!()
  end

  def forward_query(event, _measurements, metadata, pid),
    do: send(pid, {:query, event, metadata.query})

  defp insert_owner!(name), do: insert!("verify_owners (name) VALUES (?)", [name])

  defp insert_pen!(owner, label) do
    insert!("verify_pens (label, owner_id) VALUES (?, ?)", [label, owner])
  end

  defp insert!(into, params) do
    %{rows: [[id]]} = Repo.query!("INSERT INTO #{into} RETURNING id", params)
    id
  end

  defp rows(sql), do: Repo.query!(sql).rows

  defp seed_note!(title) do
    at = "2026-01-01T09:00:00Z"
    user = insert!("users (email) VALUES (?)", ["ada@example.com"])
    notebook_sql = "notebooks (name, user_id, inserted_at, updated_at) VALUES (?, ?, ?, ?)"
    notebook = insert!(notebook_sql, ["work", user, at, at])

    note_sql =
      "notes (title, notebook_id, user_id, inserted_at, updated_at) VALUES (?, ?, ?, ?, ?)"

    insert!(note_sql, [title, notebook, user, at, at])
  end

  defp matches(table, word), do: rows("SELECT rowid FROM #{table} WHERE #{table} MATCH '#{word}'")

  test "repo starts and migrations run in a fresh build path" do
    assert Path.dirname(Db.path()) == Mix.Project.build_path()
    assert rows("SELECT version FROM schema_migrations ORDER BY version") == [[1], [6], [8]]
    assert rows("SELECT count(*) FROM verify_owners") == [[0]]
    assert Support.Migrations.run!() == :ok
  end

  test "reset! clears rows and restarts ids at 1" do
    ada = insert_owner!("ada")
    _bob = insert_owner!("bob")
    assert insert_pen!(ada, "pen") == 1
    assert insert_pen!(ada, "ink") == 2

    assert Db.reset!() == :ok

    assert rows("SELECT count(*) FROM verify_owners") == [[0]]
    assert rows("SELECT count(*) FROM verify_pens") == [[0]]
    assert insert_owner!("cy") == 1
    assert insert_pen!(1, "nib") == 1
  end

  test "reset! empties the notes search index, and search works on new notes" do
    seed_note!("alpha")
    assert matches("notes_fts", "alpha") == [[1]]

    assert Db.reset!() == :ok

    seed_note!("beta")
    assert matches("notes_fts", "alpha") == []
    assert matches("notes_fts", "beta") == [[1]]
    Repo.query!("INSERT INTO notes_fts(notes_fts) VALUES ('integrity-check')")
  end

  test "reset! empties an FTS5 table that stores its own rows" do
    Repo.query!("INSERT INTO verify_words (rowid, word) VALUES (1, 'alpha')")

    assert Db.reset!() == :ok

    assert rows("SELECT count(*) FROM verify_words") == [[0]]
    Repo.query!("INSERT INTO verify_words (rowid, word) VALUES (1, 'beta')")
    assert matches("verify_words", "beta") == [[1]]
  end

  test "reset! empties an external-content FTS5 index that no trigger keeps in step" do
    owner = insert_owner!("alpha")
    Repo.query!("INSERT INTO verify_owner_index (rowid, name) VALUES (?, 'alpha')", [owner])
    _never_indexed = insert_owner!("gamma")

    assert Db.reset!() == :ok

    owner = insert_owner!("beta")
    Repo.query!("INSERT INTO verify_owner_index (rowid, name) VALUES (?, 'beta')", [owner])

    assert matches("verify_owner_index", "alpha") == []
    assert matches("verify_owner_index", "beta") == [[1]]
  end

  test "reset! empties a trigger-kept FTS5 index whose name sorts before its content table" do
    _ = insert!("verify_labels (label) VALUES (?)", ["alpha"])

    assert Db.reset!() == :ok

    assert insert!("verify_labels (label) VALUES (?)", ["beta"]) == 1
    assert matches("fts_verify_labels", "alpha") == []
    assert matches("fts_verify_labels", "beta") == [[1]]
    Repo.query!("INSERT INTO fts_verify_labels(fts_verify_labels) VALUES ('integrity-check')")
  end

  test "reset! empties a contentless FTS5 table" do
    Repo.query!("INSERT INTO verify_tokens (rowid, word) VALUES (1, 'alpha')")

    assert Db.reset!() == :ok

    assert matches("verify_tokens", "alpha") == []
    Repo.query!("INSERT INTO verify_tokens (rowid, word) VALUES (1, 'beta')")
    assert matches("verify_tokens", "beta") == [[1]]
  end

  test "a client killed mid-transaction leaves the schema and earlier rows in place" do
    assert insert_owner!("ada") == 1
    test = self()

    {pid, ref} =
      spawn_monitor(fn ->
        Repo.transact(fn ->
          insert_owner!("bob")
          send(test, :inserted)
          receive do: (:never -> {:ok, :never})
        end)
      end)

    receive do: (:inserted -> :ok)
    Process.exit(pid, :kill)
    receive do: ({:DOWN, ^ref, :process, ^pid, reason} -> assert reason == :killed)

    assert rows("SELECT id, name FROM verify_owners") == [[1, "ada"]]
    assert insert_owner!("cy") == 2
  end

  test "live_isolated renders with a session uid" do
    {:ok, view, html} = live_isolated(Support.Live.conn(7), SessionLive)

    assert html =~ ~s(<p id="uid">7</p>)
    assert render(view) =~ ~s(<p id="uid">7</p>)
  end

  test "live via the router renders and handle_params runs" do
    start_supervised!(
      {Course.Ch07.Store,
       [
         %{id: 1, title: "pen", user_id: 3, tag: "desk"},
         %{id: 2, title: "ink", user_id: 4, tag: "desk"}
       ]}
    )

    {:ok, view, html} = live(Support.Live.conn(3), "/ch07/dashboard?tag=desk")

    for page <- [html, render(view)] do
      assert page =~ ~s(<p id="mode">live</p>)
      assert page =~ ~s(<p id="count">1</p>)
      assert page =~ ~s(<p id="tag">desk</p>)
    end
  end

  test "the static render of a routed view reads the query string" do
    start_supervised!({Course.Ch07.Store, []})

    html = Support.Live.conn(3) |> get("/ch07/dashboard?tag=desk") |> html_response(200)

    assert html =~ ~s(<p id="mode">static</p>)
    assert html =~ ~s(<p id="tag">desk</p>)
  end

  test "the endpoint is not serving" do
    assert Support.Endpoint.config(:server) == false
  end

  test "the telemetry query event fires under [:review_koans, :repo, :query]" do
    id = {__MODULE__, make_ref()}
    :ok = :telemetry.attach(id, @query_event, &__MODULE__.forward_query/4, self())
    on_exit(fn -> :telemetry.detach(id) end)

    rows("SELECT 1")

    assert_received {:query, @query_event, "SELECT 1"}
  end
end
