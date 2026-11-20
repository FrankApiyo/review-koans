defmodule Review.Ch06.Titles do
  @moduledoc """
  Exact-title search. `ids_titled/1` returns the ids of the posts titled `title`, in id order;
  `title` is whatever the reader typed in the search box.
  """

  alias Support.Repo

  @spec ids_titled(String.t()) :: [pos_integer()]
  def ids_titled(title) do
    %{rows: rows} = Repo.query!("SELECT id FROM blog_posts WHERE title = '#{title}' ORDER BY id")
    List.flatten(rows)
  end
end
