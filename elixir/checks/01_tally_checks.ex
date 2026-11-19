defmodule Checks.Ch01.Tally do
  use Koans.Checks, review: Review.Ch01.Tally

  alias Koans.Hidden
  alias Review.Ch01.Tally

  @impl true
  def cases do
    [
      {:twin, "a running total",
       fn ->
         assert {:ok, {5, _}} = Hidden.isolated(fn -> total_after([{:add, 2}, {:add, 3}]) end)
       end},
      {:twin, "a stray message between adds",
       fn ->
         assert {:ok, {5, _}} =
                  Hidden.isolated(fn -> total_after([{:add, 2}, :stray, {:add, 3}]) end)
       end},
      {:exploit, "unknown messages do not pile up in the mailbox",
       fn ->
         assert {:ok, {6, 0}} =
                  Hidden.isolated(fn ->
                    total_after([{:add, 5}, :noise, {:unknown, 1}, "text", {:add, 1}])
                  end)
       end}
    ]
  end

  # One sender: the reply comes only after the tally has read every earlier message.
  defp total_after(messages) do
    tally = Tally.start()
    Enum.each(messages, &send(tally, &1))
    ref = make_ref()
    send(tally, {:total, self(), ref})

    receive do
      {^ref, total} ->
        {:message_queue_len, left} = Process.info(tally, :message_queue_len)
        {total, left}
    end
  end
end
