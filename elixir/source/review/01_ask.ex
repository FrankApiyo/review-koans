defmodule Review.Ch01.Ask do
  @moduledoc """
  `run/2` runs `work` on `input` in a monitored process. It returns `{:ok, value}`, or
  `{:error, reason}` with the process's exit reason when the work crashes.
  """

  @spec run((term() -> term()), term()) :: {:ok, term()} | {:error, term()}
  def run(work, input) do
    parent = self()
    {pid, ref} = spawn_monitor(fn -> send(parent, {:done, self(), work.(input)}) end)

    receive do
      {:done, ^pid, value} ->
        # >>> guard
        Process.demonitor(ref, [:flush])
        # === wrong: partial — drops the demonitor, so the monitor or its :DOWN outlives the call
        # <<<
        {:ok, value}

      {:DOWN, ^ref, :process, ^pid, reason} ->
        {:error, reason}
    end
  end
end
