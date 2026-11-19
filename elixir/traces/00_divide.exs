defmodule Bill do
  def split(total_cents, people) do
    share = div(total_cents, people)
    {share, rem(total_cents, people)}
  end
end

IO.inspect(Bill.split(1000, 3))
IO.inspect(Bill.split(1000, 0))
