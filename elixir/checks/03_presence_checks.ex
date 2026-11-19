defmodule Checks.Ch03.Presence do
  use Koans.Checks, review: Review.Ch03.Presence

  alias Koans.Hidden
  alias Review.Ch03.Presence

  @impl true
  def cases do
    [
      {:twin, "a process can join", fn -> assert {:ok, :ok} = Hidden.isolated(&join_once/0) end},
      {:twin, "a process that has not joined is nobody",
       fn -> assert {:ok, nil} = Hidden.isolated(&before_joining/0) end},
      {:twin, "another process is not the one that joined",
       fn -> assert {:ok, nil} = Hidden.isolated(&other_after_join/0) end},
      {:exploit, "the process that joined is known on its next call",
       fn -> assert {:ok, "ada"} = Hidden.isolated(&same_after_join/0) end}
    ]
  end

  defp join_once do
    {:ok, presence} = Presence.start_link()
    Presence.join(presence, "ada")
  end

  defp before_joining do
    {:ok, presence} = Presence.start_link()
    Presence.whoami(presence)
  end

  defp other_after_join do
    {:ok, presence} = Presence.start_link()
    :ok = Presence.join(presence, "ada")
    test = self()
    other = spawn_link(fn -> send(test, {:other, self(), Presence.whoami(presence)}) end)

    receive do
      {:other, ^other, name} -> name
    end
  end

  defp same_after_join do
    {:ok, presence} = Presence.start_link()
    :ok = Presence.join(presence, "ada")
    Presence.whoami(presence)
  end
end
