defmodule Checks.Ch02.SupervisedTask do
  use Koans.Checks, review: Review.Ch02.SupervisedTask

  alias Koans.Hidden
  alias Review.Ch02.SupervisedTask

  @impl true
  def cases do
    [
      {:twin, "work that succeeds",
       fn -> assert {:ok, {:ok, 42}} = Hidden.isolated(fn -> run(fn -> 21 * 2 end) end) end},
      {:exploit, "work that raises",
       fn ->
         assert {:ok, {:error, {%RuntimeError{message: "boom"}, _}}} =
                  Hidden.isolated(fn -> run(fn -> raise "boom" end) end)
       end},
      {:exploit, "the caller is not linked to the work",
       fn -> assert {:ok, false} = Hidden.isolated(&linked_while_running?/0) end},
      {:exploit, "a finished run leaves no monitor and no :DOWN behind",
       fn -> assert {:ok, {[], [{:keep, 1}]}} = Hidden.isolated(&leftovers_after_runs/0) end}
    ]
  end

  defp run(fun) do
    {:ok, sup} = Task.Supervisor.start_link()
    SupervisedTask.run(sup, fun)
  end

  # The work waits for :go, so the caller's links are read while the task is alive.
  defp linked_while_running? do
    test = self()
    {:ok, sup} = Task.Supervisor.start_link()

    caller =
      spawn_link(fn ->
        SupervisedTask.run(sup, fn ->
          send(test, {:started, self()})

          receive do
            :go -> :ok
          end
        end)

        send(test, {:returned, self()})
      end)

    receive do
      {:started, task} ->
        {:links, links} = Process.info(caller, :links)
        send(task, :go)

        receive do
          {:returned, ^caller} -> task in links
        end
    end
  end

  defp leftovers_after_runs do
    send(self(), {:keep, 1})
    {:ok, sup} = Task.Supervisor.start_link()
    SupervisedTask.run(sup, fn -> 21 * 2 end)
    SupervisedTask.run(sup, fn -> raise "boom" end)
    {:monitors, monitors} = Process.info(self(), :monitors)
    {:messages, messages} = Process.info(self(), :messages)
    {monitors, messages}
  end
end
