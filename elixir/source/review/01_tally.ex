defmodule Review.Ch01.Tally do
  @moduledoc """
  A running total in its own process. Send `{:add, n}` to add `n`. Send
  `{:total, caller, ref}` and it replies `{ref, total}` to `caller`.
  """

  @spec start() :: pid()
  def start, do: spawn_link(fn -> loop(0) end)

  defp loop(total) do
    receive do
      # >>> guard
      {:add, n} ->
        loop(total + n)

      # === wrong: partial — a catch-all placed first takes every message, so nothing is added or answered
      _other ->
        loop(total)

      {:add, n} ->
        loop(total + n)

      # <<<
      {:total, caller, ref} ->
        send(caller, {ref, total})
        loop(total)
      # >>> fix
      # also: receive do — a reviewer points at the receive that has no way to drop unknown messages
      # also: {:total, caller, ref} -> — a reviewer points at the last clause, where the catch-all belongs after
      # === fixed

      _other ->
        loop(total)
      # === alt: logs anything it does not know, then drops it

      unknown ->
        require Logger
        Logger.warning("tally dropped an unknown message: #{inspect(unknown)}")
        loop(total)
      # === wrong: refuses — stops the tally on any message it does not know

      _other ->
        exit(:unknown_message)
      # === wrong: partial — drops only the one stray message it was shown

      :noise ->
        loop(total)
      # <<<
    end
  end
end
