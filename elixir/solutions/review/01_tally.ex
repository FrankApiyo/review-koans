defmodule Review.Ch01.Tally do
  @moduledoc """
  A running total in its own process. Send `{:add, n}` to add `n`. Send
  `{:total, caller, ref}` and it replies `{ref, total}` to `caller`.
  """

  @spec start() :: pid()
  def start, do: spawn_link(fn -> loop(0) end)

  defp loop(total) do
    receive do
      {:add, n} ->
        loop(total + n)

      {:total, caller, ref} ->
        send(caller, {ref, total})
        loop(total)

      _other ->
        loop(total)
    end
  end
end
