defmodule Checks.Ch08.Tags do
  use Koans.Checks, review: Review.Ch08.Tags

  alias Checks.Ch08.Db
  alias Course.Ch08.Note
  alias Koans.Hidden
  alias Review.Ch08.Tags

  @impl true
  def cases do
    [
      {:twin, "new tags are created for the user, and only her own are set on the note",
       fn ->
         :ok = Support.Db.reset!()
         assert {:ok, {{:ok, %Note{}}, tags}} = Hidden.isolated(&fresh/0)
         assert [{"home", 1}, {"work", 1}] = tags
       end},
      {:twin, "a tag the user has but did not name is not set on the note",
       fn ->
         :ok = Support.Db.reset!()
         assert {:ok, {{:ok, %Note{}}, tags}} = Hidden.isolated(&unnamed/0)
         assert [{"home", 1}, {"work", 1}] = tags
       end},
      {:exploit, "another user's tag of the same name is set on the note",
       fn ->
         :ok = Support.Db.reset!()
         assert {:ok, {{:ok, %Note{}}, tags}} = Hidden.isolated(&existing/0)
         assert [1] = tags |> Enum.map(&elem(&1, 1)) |> Enum.uniq()
       end},
      {:exploit, "a tag the user already has is dropped from the note",
       fn ->
         :ok = Support.Db.reset!()
         assert {:ok, {{:ok, %Note{}}, tags}} = Hidden.isolated(&existing/0)
         assert [{"urgent", 1}, {"work", 1}] = tags
       end}
    ]
  end

  # Ada is user 1. Bob, user 2, already has a tag named "work".
  defp fresh do
    {ada, notebook} = seed()
    note = Db.note!(notebook, "one")
    result = Tags.set_note_tags(ada, note, ["work", "home"])
    {result, Db.stored_tags(note)}
  end

  # Ada already has "misc", which this note is not given.
  defp unnamed do
    {ada, notebook} = seed()
    Db.tag!(ada, "misc")
    note = Db.note!(notebook, "one")
    result = Tags.set_note_tags(ada, note, ["work", "home"])
    {result, Db.stored_tags(note)}
  end

  # Ada's first note creates her "home" and "work"; her second note then reuses "work".
  defp existing do
    {ada, notebook} = seed()
    {:ok, _} = Tags.set_note_tags(ada, Db.note!(notebook, "one"), ["work", "home"])
    note = Db.note!(notebook, "two")
    result = Tags.set_note_tags(ada, note, ["work", "urgent"])
    {result, Db.stored_tags(note)}
  end

  defp seed do
    ada = Db.scope!("ada")
    bob = Db.scope!("bob")
    Db.tag!(bob, "work")
    {ada, Db.notebook!(ada, "work")}
  end
end
