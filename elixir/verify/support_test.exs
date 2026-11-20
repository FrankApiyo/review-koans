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
    end
  end

  defmodule SessionLive do
    use Phoenix.LiveView

    def mount(_params, %{"uid" => uid}, socket), do: {:ok, assign(socket, uid: uid)}

    def render(assigns), do: ~H|<p id="uid">{@uid}</p>|
  end

  defmodule RoutedLive do
    use Phoenix.LiveView

    def mount(_params, %{"uid" => uid}, socket), do: {:ok, assign(socket, uid: uid, id: nil)}

    def handle_params(%{"id" => id}, _uri, socket), do: {:noreply, assign(socket, id: id)}

    def render(assigns), do: ~H|<p id="uid">{@uid}</p><p id="id">{@id}</p>|
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

  test "repo starts and migrations run in a fresh build path" do
    assert Path.dirname(Db.path()) == Mix.Project.build_path()
    assert rows("SELECT version FROM schema_migrations") == [[1]]
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

  test "a client killed mid-transaction leaves the schema and earlier rows in place" do
    assert insert_owner!("ada") == 1
    test = self()

    {pid, ref} =
      spawn_monitor(fn ->
        Repo.transaction(fn ->
          insert_owner!("bob")
          send(test, :inserted)
          receive do: (:never -> :ok)
        end)
      end)

    assert_receive :inserted
    Process.exit(pid, :kill)
    assert_receive {:DOWN, ^ref, :process, ^pid, :killed}

    assert rows("SELECT id, name FROM verify_owners") == [[1, "ada"]]
    assert insert_owner!("cy") == 2
  end

  test "live_isolated renders with a session uid" do
    {:ok, view, html} = live_isolated(Support.Live.conn(7), SessionLive)

    assert html =~ ~s(<p id="uid">7</p>)
    assert render(view) =~ ~s(<p id="uid">7</p>)
  end

  test "live via the router renders and handle_params runs" do
    {:ok, view, html} = live(Support.Live.conn(3), "/verify/routed/42")

    assert html =~ ~s(<p id="uid">3</p><p id="id">42</p>)
    assert render(view) =~ ~s(<p id="uid">3</p><p id="id">42</p>)
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
