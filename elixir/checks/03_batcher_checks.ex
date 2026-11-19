defmodule Checks.Ch03.Batcher do
  use Koans.Checks, review: Review.Ch03.Batcher

  alias Koans.Hidden
  alias Review.Ch03.Batcher

  @impl true
  def cases do
    [
      {:twin, "a batch of one answers its caller",
       fn -> assert {:ok, {:ok, [[:a]]}} = Hidden.isolated(&batch_of_one/0) end},
      {:twin, "a full batch is flushed in the order its items arrived",
       fn -> assert {:ok, {:ok, [[:a, :b, :c]]}} = Hidden.isolated(&last_of_three/0) end},
      {:exploit, "every caller in a batch gets :ok",
       fn -> assert {:ok, {[:ok, :ok, :ok], _}} = Hidden.isolated(&all_of_three/0) end},
      {:exploit, "no caller is still waiting once its batch is flushed",
       fn -> assert {:ok, {_, 0}} = Hidden.isolated(&all_of_three/0) end}
    ]
  end

  defp batch_of_one do
    {:ok, batcher} = Batcher.start_link(1)
    answer = Batcher.add(batcher, :a)
    {answer, Batcher.flushed(batcher)}
  end

  defp last_of_three do
    {batcher, [_first, _second, last]} = three_callers()
    {answer(last), Batcher.flushed(batcher)}
  end

  defp all_of_three do
    {batcher, callers} = three_callers()
    {Enum.map(callers, &answer/1), Batcher.pending(batcher)}
  end

  # Each caller is started only once the server has taken the one before, so the items
  # arrive as :a, :b, :c.
  defp three_callers do
    test = self()
    {:ok, batcher} = Batcher.start_link(3)

    callers =
      for {item, before} <- [a: 0, b: 1, c: 2] do
        true = Hidden.wait_until(fn -> Batcher.pending(batcher) >= before end)
        spawn_link(fn -> send(test, {:added, self(), Batcher.add(batcher, item)}) end)
      end

    {batcher, callers}
  end

  defp answer(caller) do
    receive do
      {:added, ^caller, answer} -> answer
    end
  end
end
