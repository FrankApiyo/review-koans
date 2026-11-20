# needs: deps
defmodule Notebooks do
  import Ecto.Query

  alias Course.Ch08.{Id, Note, Scope}
  alias Support.Repo

  def list_notes(%Scope{} = scope) do
    Repo.all(from n in Note, where: n.user_id == ^scope.user.id, order_by: n.id)
  end

  def fetch_note(%Scope{} = scope, id) do
    with {:ok, id} <- Id.cast(id),
         %Note{} = note <- Repo.get_by(Note, id: id, user_id: scope.user.id) do
      {:ok, note}
    else
      _ -> {:error, :not_found}
    end
  end

  def delete_note(%Scope{}, %Note{} = note), do: Repo.delete(note)
end

defmodule NotebookLive do
  use Phoenix.LiveView

  alias Course.Ch08.{Scope, User}

  def mount(_params, %{"uid" => uid}, socket) do
    scope = Scope.for_user(Support.Repo.get!(User, uid))
    {:ok, assign(socket, current_scope: scope, notes: Notebooks.list_notes(scope))}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    scope = socket.assigns.current_scope
    {:ok, note} = Notebooks.fetch_note(scope, id)
    {:ok, _note} = Notebooks.delete_note(scope, note)
    {:noreply, assign(socket, notes: Notebooks.list_notes(scope))}
  end

  def render(assigns), do: ~H"<ul>{items(@notes)}</ul>"

  # One escaped string, not a :for over the notes, so the report's template fingerprint is the
  # same on every run.
  defp items(notes) do
    Phoenix.HTML.raw(
      for note <- notes do
        ~s(<li id="note-#{note.id}">#{escape(note.title)} ) <>
          ~s(<button phx-click="delete" phx-value-id="#{note.id}">delete</button></li>)
      end
    )
  end

  defp escape(text), do: text |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
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
    level: :error,
    formatter: default.formatter,
    config: %{script: self()}
  })

alias Course.Ch08.{Note, Notebook, User}
alias Support.Repo

at = ~U[2026-01-01 09:00:00Z]
ada = Repo.insert!(%User{email: "ada@example.com"})
work = Repo.insert!(%Notebook{name: "work", user_id: ada.id, inserted_at: at, updated_at: at})

for title <- ["shopping list", "plan"] do
  note = %Note{title: title, notebook_id: work.id, user_id: ada.id}
  Repo.insert!(%{note | inserted_at: at, updated_at: at})
end

# LiveViewTest runs only inside an ExUnit test; with no formatters, ExUnit prints nothing.
ExUnit.start(autorun: false, formatters: [])

defmodule TwoTabsTest do
  use ExUnit.Case

  import Phoenix.LiveViewTest

  @endpoint Support.Endpoint

  test "Ada deletes the plan in two tabs" do
    Process.flag(:trap_exit, true)
    {:ok, first, _html} = live_isolated(Support.Live.conn(1), NotebookLive)
    {:ok, second, _html} = live_isolated(Support.Live.conn(1), NotebookLive)
    first |> element("#note-2 button") |> render_click()
    catch_exit(second |> element("#note-2 button") |> render_click())
  end
end

%{failures: 0} = ExUnit.run()

receive do
  :printed -> :ok
end
