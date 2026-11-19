defmodule Review.Ch01.ParallelMap do
  @moduledoc """
  `map/2` runs `fun` on each item in its own process and returns the results in input order.
  """

  @spec map([term()], (term() -> term())) :: [term()]
  def map(list, fun) do
    # >>> fix
    # also: receive do — a reviewer points at the receive that waits for a reply that never reaches the caller
    # also: {^pid, result} -> result — a reviewer points at the clause that matches a reply that never reaches the caller
    pids = Enum.map(list, fn x -> spawn(fn -> send(self(), {self(), fun.(x)}) end) end)
    Enum.map(pids, &await/1)
    # === fixed
    caller = self()
    pids = Enum.map(list, fn x -> spawn(fn -> send(caller, {self(), fun.(x)}) end) end)
    Enum.map(pids, &await/1)
    # === alt: one Task per item, awaited in input order
    list
    |> Enum.map(fn x -> Task.async(fn -> fun.(x) end) end)
    |> Task.await_many()
    # === wrong: refuses — refuses to map at all
    _ = {list, fun}
    raise ArgumentError, "parallel map is switched off"
    # === wrong: partial — sends to the caller but takes results in arrival order
    caller = self()
    pids = Enum.map(list, fn x -> spawn(fn -> send(caller, {self(), fun.(x)}) end) end)

    Enum.map(pids, fn _pid ->
      receive do
        {_worker, result} -> result
      end
    end)
    # <<<
  end

  defp await(pid) do
    receive do
      {^pid, result} -> result
    end
  end
end
