defmodule Checks.HiddenExit.Isolated do
  @behaviour Koans.Checks

  import ExUnit.Assertions

  alias Review.HiddenExit.Divider

  @impl true
  def cases do
    [
      {:exploit, "no parts",
       fn -> assert Koans.Hidden.isolated(fn -> Divider.share(6413, 0) end) == {:ok, 0} end}
    ]
  end
end

defmodule Checks.HiddenExit.Unisolated do
  @behaviour Koans.Checks

  import ExUnit.Assertions

  alias Review.HiddenExit.Divider

  @impl true
  def cases do
    [
      {:exploit, "no parts", fn -> assert Divider.share(6413, 0) == 0 end}
    ]
  end
end
