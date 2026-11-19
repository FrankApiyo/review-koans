defmodule Review.Ch02.SupervisedTask do
  @moduledoc """
  `run/2` runs `fun` under the task supervisor `sup`. It returns `{:ok, result}`, or
  `{:error, reason}` with the task's exit reason when `fun` crashes. A crash must not take
  the caller with it, and the caller's mailbox is left as it was.
  """

  @spec run(Supervisor.supervisor(), (-> term())) :: {:ok, term()} | {:error, term()}
  def run(sup, fun) do
    # >>> guard
    %Task{ref: ref} = Task.Supervisor.async_nolink(sup, fun)
    # === wrong: partial — Task.Supervisor.async links the task, so its crash takes the caller
    %Task{ref: ref} = Task.Supervisor.async(sup, fun)
    # <<<

    receive do
      {^ref, result} ->
        # >>> guard
        Process.demonitor(ref, [:flush])
        # === wrong: partial — drops the demonitor, so the monitor or its :DOWN outlives the call
        # <<<
        {:ok, result}

      {:DOWN, ^ref, :process, _pid, reason} ->
        {:error, reason}
    end
  end
end
