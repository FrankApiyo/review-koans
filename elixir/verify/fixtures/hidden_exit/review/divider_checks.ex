defmodule Checks.HiddenExit.Isolated do
  use Koans.Checks, review: Review.HiddenExit.Divider

  alias Review.HiddenExit.Divider

  @impl true
  def cases do
    [
      {:exploit, "no parts",
       fn -> assert {:ok, 0} = Koans.Hidden.isolated(fn -> Divider.share(6413, 0) end) end}
    ]
  end
end

defmodule Checks.HiddenExit.Unisolated do
  use Koans.Checks, review: Review.HiddenExit.Divider

  alias Review.HiddenExit.Divider

  @impl true
  def cases do
    [
      {:exploit, "no parts", fn -> assert 0 = Divider.share(6413, 0) end}
    ]
  end
end
