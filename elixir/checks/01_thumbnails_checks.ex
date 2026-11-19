defmodule Checks.Ch01.Thumbnails do
  use Koans.Checks, review: Review.Ch01.Thumbnails

  alias Koans.Hidden
  alias Review.Ch01.Thumbnails

  @impl true
  def cases do
    [
      {:twin, "an image that resizes",
       fn ->
         assert {:ok, {:ok, %{w: 50, h: 25}}} = Hidden.isolated(fn -> render_resizable() end)
       end},
      {:exploit, "a worker that crashes before replying",
       fn ->
         assert {:ok, {:error, {:function_clause, _}}} =
                  Hidden.isolated(fn -> render_without_area() end)
       end},
      {:exploit, "a finished render leaves no monitor and no :DOWN behind",
       fn -> assert {:ok, {[], []}} = Hidden.isolated(&leftovers_after_renders/0) end}
    ]
  end

  defp render_resizable, do: Thumbnails.render(%{w: 100, h: 50})

  defp render_without_area, do: Thumbnails.render(%{w: 0, h: 10})

  defp leftovers_after_renders do
    render_resizable()
    render_without_area()
    {:monitors, monitors} = Process.info(self(), :monitors)
    {:messages, messages} = Process.info(self(), :messages)
    {monitors, for({:DOWN, _, _, _, _} = down <- messages, do: down)}
  end
end
