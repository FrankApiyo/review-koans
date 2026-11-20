defmodule Checks.Ch08.UpdateNote do
  use Koans.Checks, review: Review.Ch08.UpdateNote

  alias Checks.Ch08.Db
  alias Course.Ch08.Note
  alias Koans.Hidden
  alias Review.Ch08.UpdateNote

  @impl true
  def cases do
    [
      {:twin, "a tab saves twice in a row, each time from the note its last save returned",
       fn ->
         :ok = Support.Db.reset!()
         assert {:ok, {"second", "second"}} = Hidden.isolated(&save_twice/0)
       end},
      {:exploit,
       "a save from a copy another tab has saved over overwrites it, or raises instead of returning an error",
       fn ->
         :ok = Support.Db.reset!()
         assert {:ok, {{:error, changeset}, "from A"}} = Hidden.isolated(&two_tabs/0)
         assert [lock_version: {_message, _details}] = changeset.errors
       end}
    ]
  end

  defp seed do
    ada = Db.scope!("ada")
    Db.note!(Db.notebook!(ada, "work"), "draft")
  end

  defp save_twice do
    note = seed()
    {:ok, first} = UpdateNote.update_note(note, form(note, "first"))
    {:ok, second} = UpdateNote.update_note(first, form(first, "second"))
    {second.title, stored_title(note)}
  end

  # Both tabs load the note at the same version; A saves first.
  defp two_tabs do
    note = seed()
    tab_a = Support.Repo.get!(Note, note.id)
    tab_b = Support.Repo.get!(Note, note.id)
    {:ok, _} = UpdateNote.update_note(tab_a, form(tab_a, "from A"))
    result = UpdateNote.update_note(tab_b, form(tab_b, "from B"))
    {result, stored_title(note)}
  end

  # The editor's form sends back the lock_version it was rendered with.
  defp form(%Note{lock_version: version}, title) do
    %{"title" => title, "lock_version" => Integer.to_string(version)}
  end

  defp stored_title(%Note{id: id}), do: Support.Repo.get!(Note, id).title
end
