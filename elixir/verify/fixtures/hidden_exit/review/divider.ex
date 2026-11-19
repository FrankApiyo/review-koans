defmodule Review.HiddenExit.Divider do
  def share(total, parts) do
    worker = spawn_link(fn -> receive(do: ({:share, from, t, p} -> send(from, div(t, p)))) end)
    send(worker, {:share, self(), total, parts})
    receive(do: (share -> share))
  end
end
