defmodule Review.HiddenTimeout.Queue do
  def next([]), do: receive(do: ({:item, item} -> {item, []}))
  def next([item | rest]), do: {item, rest}
end
