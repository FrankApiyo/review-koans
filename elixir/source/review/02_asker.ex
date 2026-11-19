defmodule Review.Ch02.Asker do
  @moduledoc """
  `ask/2` sends `{:ask, self(), ref, question}` to a server and waits for its
  `{:answer, ref, answer}`. It returns `{:ok, answer}`, or `{:error, reason}` when the server
  dies first. Callers are long-lived and ask many times.
  """

  @spec ask(pid(), term()) :: {:ok, term()} | {:error, term()}
  def ask(server, question) do
    ref = Process.monitor(server)
    send(server, {:ask, self(), ref, question})

    receive do
      # >>> fix
      # also: ref = Process.monitor(server) — reviewers point at the monitor that is never removed
      {:answer, ^ref, answer} ->
        {:ok, answer}
      # === fixed
      {:answer, ^ref, answer} ->
        Process.demonitor(ref, [:flush])
        {:ok, answer}
      # === alt: demonitor, then take a :DOWN that is already waiting
      {:answer, ^ref, answer} ->
        Process.demonitor(ref)

        receive do
          {:DOWN, ^ref, :process, _pid, _reason} -> :ok
        after
          0 -> :ok
        end

        {:ok, answer}
      # === wrong: refuses — takes the answer but reports a failure
      {:answer, ^ref, _answer} ->
        Process.demonitor(ref, [:flush])
        {:error, :refused}
      # === wrong: partial — removes the monitor but leaves a :DOWN that is already waiting
      {:answer, ^ref, answer} ->
        Process.demonitor(ref)
        {:ok, answer}
      # === wrong: partial — removes the monitor, then empties the whole mailbox
      {:answer, ^ref, answer} ->
        Process.demonitor(ref)
        {:messages, waiting} = Process.info(self(), :messages)
        Enum.each(waiting, fn message -> receive(do: (^message -> :ok)) end)
        {:ok, answer}
      # === wrong: partial — removes the monitor, then drops every waiting :DOWN, other monitors' too
      {:answer, ^ref, answer} ->
        Process.demonitor(ref)
        {:messages, waiting} = Process.info(self(), :messages)

        for {:DOWN, _, :process, _, _} = down <- waiting do
          receive(do: (^down -> :ok))
        end

        {:ok, answer}
      # <<<

      {:DOWN, ^ref, :process, _pid, reason} ->
        {:error, reason}
    end
  end
end
