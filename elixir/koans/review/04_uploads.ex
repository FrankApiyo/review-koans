defmodule Review.Ch04.Uploads do
  @moduledoc """
  Processes each upload in its own process under a `DynamicSupervisor`, so one bad file does
  not stop the others. `process/3` runs `fun.(upload)` and returns `{:ok, pid}`.
  """

  @spec start_link() :: Supervisor.on_start()
  def start_link, do: DynamicSupervisor.start_link(strategy: :one_for_one)

  @spec process(pid(), String.t(), (String.t() -> any())) :: DynamicSupervisor.on_start_child()
  def process(sup, upload, fun) do
    spec = %{
      id: upload,
      start: {Task, :start_link, [fn -> fun.(upload) end]},
      restart: :temporary
    }

    DynamicSupervisor.start_child(sup, spec)
  end
end
