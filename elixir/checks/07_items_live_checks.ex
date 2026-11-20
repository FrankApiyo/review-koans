defmodule Checks.Ch07.ItemsLive do
  use Koans.Checks, review: Review.Ch07.ItemsLive

  alias Checks.Ch07.OwnerOnly
  alias Review.Ch07.ItemsLive

  @impl true
  def cases do
    [
      {:twin, "a user deletes one of their own items",
       fn ->
         assert {:ok, {["apple", "bread"], ["item-3", "item-4"]}} =
                  OwnerOnly.own(ItemsLive)
       end},
      {:exploit, "a delete event that names another user's item",
       fn ->
         assert {:ok, {["Bob's plan"], []}} =
                  OwnerOnly.forged(ItemsLive, "delete")
       end},
      {:exploit, "another user's item is answered differently from a missing one",
       fn ->
         assert {:ok, {page, page}} =
                  OwnerOnly.not_yours_then_missing(ItemsLive, "delete")
       end}
    ]
  end
end
