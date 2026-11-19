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
      {:answer, ^ref, answer} ->
        {:ok, answer}

      {:DOWN, ^ref, :process, _pid, reason} ->
        {:error, reason}
    end
  end
end
