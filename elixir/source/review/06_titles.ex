defmodule Review.Ch06.Titles do
  @moduledoc """
  Exact-title search. `ids_titled/1` returns the ids of the posts titled `title`, in id order;
  `title` is whatever the reader typed in the search box.
  """

  alias Support.Repo

  @spec ids_titled(String.t()) :: [pos_integer()]
  def ids_titled(title) do
    # >>> fix
    %{rows: rows} = Repo.query!("SELECT id FROM blog_posts WHERE title = '#{title}' ORDER BY id")
    # === fixed
    %{rows: rows} = Repo.query!("SELECT id FROM blog_posts WHERE title = ? ORDER BY id", [title])
    # === alt: an Ecto query with the title pinned
    require Ecto.Query
    query = Ecto.Query.from(p in Course.Ch06.Post, where: p.title == ^title, order_by: p.id)
    rows = Repo.all(Ecto.Query.select(query, [p], [p.id]))
    # === wrong: refuses — finds nothing, whatever the title
    _ = title
    rows = []
    # === wrong: partial — strips quotes, so a title with an apostrophe is never found
    stripped = String.replace(title, "'", "")
    %{rows: rows} = Repo.query!("SELECT id FROM blog_posts WHERE title = '#{stripped}' ORDER BY id")
    # === wrong: partial — doubles quotes by hand, but SQL text cannot carry every byte a title can
    escaped = String.replace(title, "'", "''")
    %{rows: rows} = Repo.query!("SELECT id FROM blog_posts WHERE title = '#{escaped}' ORDER BY id")
    # <<<
    List.flatten(rows)
  end
end
