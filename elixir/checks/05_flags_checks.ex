defmodule Checks.Ch05.Flags do
  use Koans.Checks, review: Review.Ch05.Flags

  alias Koans.Hidden
  alias Review.Ch05.Flags

  @impl true
  def cases do
    [
      {:twin, "a flag nobody set reads nil",
       fn -> assert {:ok, nil} = Hidden.isolated(fn -> with_flags(&unset_flag/0) end) end},
      {:twin, "a flag that was set reads back",
       fn -> assert {:ok, true} = Hidden.isolated(fn -> with_flags(&set_flag/0) end) end},
      {:exploit, "a flag outlives the request that read the flags first",
       fn -> assert {:ok, true} = Hidden.isolated(fn -> with_flags(&reader_first/0) end) end}
    ]
  end

  defp unset_flag, do: Flags.get(:beta_search)

  defp set_flag do
    :ok = Flags.put(:new_checkout, true)
    Flags.get(:new_checkout)
  end

  defp reader_first do
    test = self()

    {reader, ref} =
      spawn_monitor(fn ->
        nil = Flags.get(:other)
        send(test, {:read, self()})

        receive do
          :done -> :ok
        end
      end)

    receive do
      {:read, ^reader} -> :ok = Flags.put(:dark_mode, true)
    end

    send(reader, :done)

    receive do
      {:DOWN, ^ref, :process, ^reader, _reason} -> :ok
    end

    true = Hidden.wait_until(&no_orphan_table?/0)
    Flags.get(:dark_mode)
  end

  # The flags server is registered and its table is named, so each case waits for whatever an
  # earlier case left behind to be gone, and stops its own tree before it returns.
  defp with_flags(fun) do
    true = Hidden.wait_until(fn -> no_orphan_table?() and is_nil(Process.whereis(Flags)) end)
    {:ok, sup} = Supervisor.start_link([Flags], strategy: :one_for_one)
    result = fun.()
    :ok = Supervisor.stop(sup)
    result
  end

  # A table goes when its owner dies (documented), but not necessarily before the owner's
  # :DOWN arrives, so wait until no :flags table is left whose owner has died.
  defp no_orphan_table? do
    case :ets.whereis(:flags) do
      :undefined -> true
      table -> owner_alive?(table)
    end
  end

  defp owner_alive?(table) do
    case :ets.info(table, :owner) do
      :undefined -> true
      owner -> Process.alive?(owner)
    end
  end
end
