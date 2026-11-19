defmodule Review.Ch01.ParallelMap do
  @moduledoc """
  `map/2` runs `fun` on each item in its own process and returns the results in input order.
  """

  @spec map([term()], (term() -> term())) :: [term()]
  def map(list, fun) do
    caller = self()
    pids = Enum.map(list, fn x -> spawn(fn -> send(caller, {self(), fun.(x)}) end) end)
    Enum.map(pids, &await/1)
  end

  defp await(pid) do
    receive do
      {^pid, result} -> result
    end
  end
end
