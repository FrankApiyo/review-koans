defmodule Checks.HiddenTimeout.Queue do
  @behaviour Koans.Checks

  import ExUnit.Assertions

  alias Review.HiddenTimeout.Queue

  @impl true
  def cases do
    [
      {:exploit, "an empty queue", fn -> assert Queue.next([]) == {:empty_5531, []} end}
    ]
  end
end
