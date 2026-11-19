defmodule Checks.Ch01.Thumbnails do
  use Koans.Checks, review: Review.Ch01.Thumbnails

  alias Course.Ch01.Thumb
  alias Koans.Hidden
  alias Review.Ch01.Thumbnails

  @impl true
  def cases do
    [
      {:twin, "an image that resizes",
       fn -> assert {:ok, {:ok, %{w: 50, h: 25}}} = Hidden.isolated(&render_resizable/0) end},
      {:exploit, "a worker that crashes before replying",
       fn ->
         assert {:ok, {:error, {:function_clause, _}}} = Hidden.isolated(&render_without_area/0)
       end},
      {:exploit, "a finished render leaves no monitor and no :DOWN behind",
       fn -> assert {:ok, {[], []}} = Hidden.isolated(&leftovers_after_renders/0) end}
    ]
  end

  defp render_resizable, do: Thumbnails.render(%{w: 100, h: 50})

  defp render_without_area, do: Thumbnails.render(%{w: 0, h: 10}, held_until_waiting(self()))

  defp leftovers_after_renders do
    render_resizable()
    render_without_area()
    {:monitors, monitors} = Process.info(self(), :monitors)
    {:messages, messages} = Process.info(self(), :messages)
    {monitors, for({:DOWN, _, _, _, _} = down <- messages, do: down)}
  end

  # The worker crashes only once the caller waits in its receive, so a monitor the caller set
  # after spawning is already in place, whichever process the scheduler runs first.
  defp held_until_waiting(caller) do
    fn image ->
      wait_for_receive(caller)
      Thumb.resize!(image)
    end
  end

  defp wait_for_receive(caller) do
    if not Hidden.wait_until(fn -> waiting_or_gone?(caller) end), do: wait_for_receive(caller)
  end

  defp waiting_or_gone?(pid) do
    case Process.info(pid, :status) do
      {:status, :waiting} -> true
      nil -> true
      _running -> false
    end
  end
end
