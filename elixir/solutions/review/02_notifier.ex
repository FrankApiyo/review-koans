defmodule Review.Ch02.Notifier do
  @moduledoc """
  `deliver_all/2` hands each address to `deliver` in its own process and returns `:ok` at
  once, without waiting for any delivery. A delivery that crashes on a bad address should
  cost that one notification and nothing else.
  """

  @spec deliver_all([String.t()], (String.t() -> term())) :: :ok
  def deliver_all(addrs, deliver) do
    Enum.each(addrs, fn addr ->
      spawn(fn -> deliver.(addr) end)
    end)

    :ok
  end
end
