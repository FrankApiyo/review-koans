defmodule Checks.Ch06.Db do
  @moduledoc false

  alias Course.Ch06.{Comment, Post, User}
  alias Support.Repo

  @query_event [:review_koans, :repo, :query]

  @spec user!(String.t()) :: %User{}
  def user!(name), do: Repo.insert!(%User{email: name <> "@example.com"})

  @spec post!(%User{}, String.t()) :: %Post{}
  def post!(user, title), do: Repo.insert!(%Post{user_id: user.id, title: title})

  @spec comment!(%Post{}, String.t()) :: %Comment{}
  def comment!(post, body), do: Repo.insert!(%Comment{post_id: post.id, body: body})

  @doc """
  Runs `fun` through `Koans.Hidden.isolated/1` and returns its outcome with the SQL of every
  query the repo ran meanwhile. The handler is detached on every path: `isolated/1` returns
  whatever `fun` does, a raise, an exit or a hang included.
  """
  @spec queries_during((-> any())) :: {term(), [String.t()]}
  def queries_during(fun) do
    table = :ets.new(:queries, [:duplicate_bag, :public])
    handler = {__MODULE__, make_ref()}
    :ok = :telemetry.attach(handler, @query_event, &__MODULE__.record/4, table)
    outcome = Koans.Hidden.isolated(fun)
    :ok = :telemetry.detach(handler)
    queries = for {:query, sql} <- :ets.tab2list(table), do: sql
    true = :ets.delete(table)
    {outcome, queries}
  end

  @doc false
  def record(_event, _measurements, %{query: sql}, table), do: :ets.insert(table, {:query, sql})

  @spec raised((-> any())) :: module() | :nothing_raised
  def raised(fun) do
    fun.()
    :nothing_raised
  rescue
    error -> error.__struct__
  end
end
