defmodule Checks.Ch07.ArchiveLive do
  use Koans.Checks, review: Review.Ch07.ArchiveLive

  alias Checks.Ch07.OwnerOnly
  alias Review.Ch07.ArchiveLive

  @impl true
  def cases do
    [
      {:twin, "a user archives one of their own items",
       fn ->
         assert {:ok, {["apple", "bread"], ["item-3", "item-4"]}} =
                  OwnerOnly.own(ArchiveLive)
       end},
      {:exploit, "an archive event that names another user's item",
       fn ->
         assert {:ok, {["Bob's plan"], ["item-1", "item-3", "item-4"]}} =
                  OwnerOnly.forged(ArchiveLive, "archive")
       end},
      {:exploit, "another user's item is answered differently from a missing one",
       fn ->
         assert {:ok, {page, page}} =
                  OwnerOnly.not_yours_then_missing(ArchiveLive, "archive")
       end},
      {:exploit, "an archive event whose id is not a number",
       fn ->
         assert {:ok, ["item-1", "item-3", "item-4"]} =
                  OwnerOnly.malformed(ArchiveLive, "archive")
       end}
    ]
  end
end
