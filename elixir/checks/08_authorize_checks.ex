defmodule Checks.Ch08.Authorize do
  use Koans.Checks, review: Review.Ch08.Authorize

  alias Checks.Ch08.Db
  alias Course.Ch08.{Note, Notebook, Scope}
  alias Koans.Hidden
  alias Review.Ch08.Authorize

  @impl true
  def cases do
    [
      {:twin, "a user opens her own notebook",
       fn ->
         :ok = Support.Db.reset!()
         assert {:ok, %Notebook{name: "work"}} = Hidden.isolated(&own/0)
       end},
      {:exploit, "another user's notebook is not refused as a missing one is",
       fn ->
         :ok = Support.Db.reset!()
         assert {:ok, {Ecto.NoResultsError, Ecto.NoResultsError}} = Hidden.isolated(&not_yours/0)
       end},
      {:exploit, "a record with no owner is given to whoever asks",
       fn ->
         :ok = Support.Db.reset!()
         assert {:ok, {Ecto.NoResultsError, Ecto.NoResultsError}} = Hidden.isolated(&unowned/0)
       end}
    ]
  end

  defp own do
    ada = Db.scope!("ada")
    notebook = Db.notebook!(ada, "work")
    Authorize.get_notebook!(ada, Integer.to_string(notebook.id))
  end

  defp not_yours do
    ada = Db.scope!("ada")
    bob = Db.scope!("bob")
    notebook = Db.notebook!(ada, "work")

    {Db.raised(fn -> Authorize.get_notebook!(bob, notebook.id) end),
     Db.raised(fn -> Authorize.get_notebook!(bob, 999_999) end)}
  end

  defp unowned do
    signed_in = %Scope{user: %{id: 1}}
    signed_out = %Scope{user: nil}

    {Db.raised(fn -> Authorize.authorize!(signed_in, %Note{user_id: nil}) end),
     Db.raised(fn -> Authorize.authorize!(signed_out, %Note{user_id: nil}) end)}
  end
end
