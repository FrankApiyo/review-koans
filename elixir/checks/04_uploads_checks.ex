defmodule Checks.Ch04.Uploads do
  use Koans.Checks, review: Review.Ch04.Uploads

  alias Koans.Hidden
  alias Review.Ch04.Uploads

  @impl true
  def cases do
    [
      {:twin, "a good upload finishes next to a corrupt one",
       fn -> assert {:ok, "a.png"} = Hidden.isolated(&good_next_to_corrupt/0) end},
      {:exploit, "a corrupt upload runs once, and the supervisor stays up",
       fn -> assert {:ok, {true, 1}} = Hidden.isolated(&corrupt_upload_runs/0) end}
    ]
  end

  # Trapping exits keeps this process alive if the supervisor gives up.
  defp good_next_to_corrupt do
    Process.flag(:trap_exit, true)
    test = self()
    {:ok, sup} = Uploads.start_link()
    {:ok, _corrupt} = Uploads.process(sup, "bad.png", fn _upload -> raise "corrupt" end)
    {:ok, _good} = Uploads.process(sup, "a.png", fn upload -> send(test, {:done, upload}) end)

    receive do
      {:done, upload} -> upload
    end
  end

  defp corrupt_upload_runs do
    Process.flag(:trap_exit, true)
    runs = :counters.new(1, [])
    {:ok, sup} = Uploads.start_link()

    {:ok, _corrupt} =
      Uploads.process(sup, "bad.png", fn _upload ->
        :counters.add(runs, 1, 1)
        raise "corrupt"
      end)

    true = Hidden.wait_until(fn -> idle?(sup) end)
    {Process.alive?(sup), :counters.get(runs, 1)}
  end

  defp idle?(sup) do
    case DynamicSupervisor.count_children(sup) do
      %{active: 0} -> true
      _running -> false
    end
  catch
    :exit, _reason -> true
  end
end
