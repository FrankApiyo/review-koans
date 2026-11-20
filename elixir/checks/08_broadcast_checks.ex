defmodule Checks.Ch08.Broadcast do
  use Koans.Checks, review: Review.Ch08.Broadcast

  alias Checks.Ch08.Db
  alias Course.Ch08.{Note, Notebook}
  alias Koans.Hidden
  alias Review.Ch08.Broadcast

  @impl true
  def cases do
    [
      {:twin, "a saved note is announced to the owner's tabs",
       fn ->
         :ok = Support.Db.reset!()

         assert {:ok, {{:ok, %Note{}}, [{:note_saved, %Note{title: "plan"}}]}} =
                  Hidden.isolated(&save_note/0)
       end},
      {:twin, "a new notebook is announced to the owner's tabs",
       fn ->
         :ok = Support.Db.reset!()

         assert {:ok, {{:ok, %Notebook{}}, [{:notebook_created, %Notebook{name: "home"}}]}} =
                  Hidden.isolated(&create_notebook/0)
       end},
      {:exploit,
       "a save that fails validation is announced, or raises instead of returning its error",
       fn ->
         :ok = Support.Db.reset!()
         assert {:ok, {{:error, %Ecto.Changeset{}}, []}} = Hidden.isolated(&blank_title/0)
       end}
    ]
  end

  # PubSub delivers to subscribers on this node from the broadcasting process, and here that is
  # the subscriber itself, so anything broadcast is already in its mailbox when the call returns.
  defp save_note do
    {ada, note} = seed()
    result = Broadcast.update_note(ada, note, %{"title" => "plan"})
    {result, Db.mailbox()}
  end

  defp create_notebook do
    {ada, _note} = seed()
    result = Broadcast.create_notebook(ada, %{"name" => "home"})
    {result, Db.mailbox()}
  end

  defp blank_title do
    {ada, note} = seed()
    result = Broadcast.update_note(ada, note, %{"title" => ""})
    {result, Db.mailbox()}
  end

  # Subscribed to Ada's topic and Bob's: an announcement belongs on its owner's topic only.
  defp seed do
    ada = Db.scope!("ada")
    bob = Db.scope!("bob")
    :ok = Phoenix.PubSub.subscribe(Support.PubSub, Broadcast.topic(ada))
    :ok = Phoenix.PubSub.subscribe(Support.PubSub, Broadcast.topic(bob))
    {ada, Db.note!(Db.notebook!(ada, "work"), "draft")}
  end
end
