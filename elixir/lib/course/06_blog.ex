defmodule Course.Ch06.User do
  use Ecto.Schema

  schema "blog_users" do
    field :email, :string
    has_many :posts, Course.Ch06.Post
    timestamps(type: :utc_datetime)
  end
end

defmodule Course.Ch06.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "blog_posts" do
    field :title, :string
    field :body, :string
    field :views, :integer, default: 0
    belongs_to :user, Course.Ch06.User
    has_many :comments, Course.Ch06.Comment
    timestamps(type: :utc_datetime)
  end

  @doc "Casts a post's title and body; the title is required."
  @spec changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :body])
    |> validate_required([:title])
  end
end

defmodule Course.Ch06.Comment do
  use Ecto.Schema

  schema "blog_comments" do
    field :body, :string
    belongs_to :post, Course.Ch06.Post
    timestamps(type: :utc_datetime)
  end
end
