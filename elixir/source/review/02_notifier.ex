defmodule Review.Ch02.Notifier do
  @moduledoc """
  `deliver_all/2` hands each address to `deliver` in its own process and returns `:ok` at
  once, without waiting for any delivery. A delivery that crashes on a bad address should
  cost that one notification and nothing else.
  """

  @spec deliver_all([String.t()], (String.t() -> term())) :: :ok
  def deliver_all(addrs, deliver) do
    Enum.each(addrs, fn addr ->
      # >>> fix
      spawn_link(fn -> deliver.(addr) end)
      # === fixed
      spawn(fn -> deliver.(addr) end)
      # === alt: an unlinked, unsupervised Task
      Task.start(fn -> deliver.(addr) end)
      # === wrong: refuses — refuses to deliver anything
      _ = {addr, deliver}
      raise ArgumentError, "delivery is switched off"
      # === wrong: partial — rescues around spawn_link, which cannot catch a crash in another process
      try do
        spawn_link(fn -> deliver.(addr) end)
      rescue
        _error -> :error
      end
      # === wrong: partial — monitors each delivery but never reads or removes the monitor
      spawn_monitor(fn -> deliver.(addr) end)
      # === wrong: partial — Task.async links the task to the caller
      Task.async(fn -> deliver.(addr) end)
      # <<<
    end)

    :ok
  end
end
