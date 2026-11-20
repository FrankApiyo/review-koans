defmodule Checks.Ch07.Live do
  @moduledoc false

  import Phoenix.ConnTest, only: [get: 2]
  import Phoenix.LiveViewTest

  alias Course.Ch07.Store

  @endpoint Support.Endpoint
  @ada 1
  @bob 2

  @spec ada() :: pos_integer()
  def ada, do: @ada

  @spec bob() :: pos_integer()
  def bob, do: @bob

  @doc "Ada (user 1) has tea, apple and bread; Bob (user 2) has his plan."
  @spec items() :: [map()]
  def items do
    [
      %{id: 1, title: "tea", user_id: @ada, tag: "drink"},
      %{id: 2, title: "Bob's plan", user_id: @bob, tag: "food"},
      %{id: 3, title: "apple", user_id: @ada, tag: "food"},
      %{id: 4, title: "bread", user_id: @ada, tag: "food"}
    ]
  end

  @doc """
  Opens views with `open` in the test process, which LiveViewTest requires, then runs
  `interact` on them through `Koans.Hidden.isolated/1`, so a view that crashes or hangs fails
  the case. Each case gets a fresh store, and its views are stopped before the store.

  A view's client process is linked to the test process and exits some time after its view
  does, so the test process keeps trapping exits until the koan ends.
  """
  @spec check((-> [{struct(), String.t()}]), ([{struct(), String.t()}] -> any())) ::
          {:ok, any()} | {:down, term()} | :timeout
  def check(open, interact) do
    ExUnit.Callbacks.start_supervised!({Store, items()})
    Process.flag(:trap_exit, true)
    views = open.()
    outcome = Koans.Hidden.isolated(fn -> interact.(views) end)
    Enum.each(views, fn {view, _html} -> stop(view) end)
    :ok = ExUnit.Callbacks.stop_supervised!(Store)
    outcome
  end

  @spec open(module(), pos_integer()) :: {struct(), String.t()}
  def open(view_module, uid) do
    {:ok, view, html} = live_isolated(Support.Live.conn(uid), view_module, on_error: :raise)
    {view, html}
  end

  @spec visit(pos_integer(), String.t()) :: {struct(), String.t()}
  def visit(uid, path) do
    {:ok, view, html} = live(Support.Live.conn(uid), path, on_error: :raise)
    {view, html}
  end

  @doc """
  Runs `action` in a process of its own: what it returns, or `:stopped` when it exits because
  the view it drives has stopped. A view may stop on a forged or malformed value.
  """
  @spec attempt((-> term())) :: term() | :stopped | :timeout
  def attempt(action) do
    case Koans.Hidden.isolated(action) do
      {:ok, result} -> result
      {:down, _reason} -> :stopped
      :timeout -> :timeout
    end
  end

  @doc "The text of each list row, in page order."
  @spec titles(String.t()) :: [String.t()]
  def titles(html), do: html |> LazyHTML.from_fragment() |> LazyHTML.query("li") |> texts()

  @doc "The id of each list row, in page order."
  @spec rows(String.t()) :: [String.t()]
  def rows(html) do
    html |> LazyHTML.from_fragment() |> LazyHTML.query("li") |> LazyHTML.attribute("id")
  end

  @spec text(String.t(), String.t()) :: String.t()
  def text(html, selector) do
    html
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(selector)
    |> LazyHTML.text()
    |> String.trim()
  end

  @doc "The titles of `uid`'s items that are neither deleted nor archived."
  @spec kept(pos_integer()) :: [String.t()]
  def kept(uid), do: Enum.map(Store.for_user(uid), & &1.title)

  defp texts(nodes), do: Enum.map(nodes, &(&1 |> LazyHTML.text() |> String.trim()))

  defp stop(view) do
    ref = Process.monitor(view.pid)
    Process.exit(view.pid, :kill)

    receive do
      {:DOWN, ^ref, :process, _pid, _reason} -> :ok
    end
  end
end
