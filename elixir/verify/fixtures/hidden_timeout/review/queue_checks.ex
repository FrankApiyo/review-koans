defmodule Checks.HiddenTimeout.Queue do
  use Koans.Checks, review: Review.HiddenTimeout.Queue

  alias Review.HiddenTimeout.Queue

  @impl true
  def cases do
    [
      {:exploit, "an empty queue", fn -> assert {:empty_5531, []} = Queue.next([]) end}
    ]
  end
end
