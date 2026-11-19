defmodule Checks.Ch01.Ask do
  use Koans.Checks, review: Review.Ch01.Ask

  alias Course.Ch01.Thumb
  alias Koans.Hidden
  alias Review.Ch01.Ask

  @impl true
  def cases do
    [
      {:twin, "work that succeeds",
       fn -> assert {:ok, {:ok, %{w: 50, h: 25}}} = Hidden.isolated(&ask_resizable/0) end},
      {:exploit, "work that crashes",
       fn ->
         assert {:ok, {:error, {:function_clause, _}}} = Hidden.isolated(&ask_without_area/0)
       end},
      {:exploit, "a finished call leaves no monitor and no :DOWN behind",
       fn -> assert {:ok, {[], []}} = Hidden.isolated(&leftovers_after_calls/0) end}
    ]
  end

  defp ask_resizable, do: Ask.run(&Thumb.resize!/1, %{w: 100, h: 50})

  defp ask_without_area, do: Ask.run(&Thumb.resize!/1, %{w: 0, h: 10})

  defp leftovers_after_calls do
    ask_resizable()
    ask_without_area()
    {:monitors, monitors} = Process.info(self(), :monitors)
    {:messages, messages} = Process.info(self(), :messages)
    {monitors, for({:DOWN, _, _, _, _} = down <- messages, do: down)}
  end
end
