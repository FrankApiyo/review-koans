defmodule Course.Ch08.User do
  use Ecto.Schema

  schema "users" do
    field :email, :string
  end
end

defmodule Course.Ch08.Scope do
  @moduledoc "Who is asking. Every notebook function takes the scope first."

  defstruct [:user]

  @type t :: %__MODULE__{user: %Course.Ch08.User{} | nil}

  @spec for_user(%Course.Ch08.User{}) :: t()
  def for_user(user), do: %__MODULE__{user: user}
end

defmodule Course.Ch08.Id do
  @moduledoc "Ids from URLs and events, cast to a positive 64-bit integer."

  @max 9_223_372_036_854_775_807

  @spec cast(term()) :: {:ok, pos_integer()} | :error
  def cast(id) do
    case Ecto.Type.cast(:id, id) do
      {:ok, id} when id in 1..@max//1 -> {:ok, id}
      _ -> :error
    end
  end
end

defmodule Course.Ch08.Notebook do
  use Ecto.Schema

  schema "notebooks" do
    field :name, :string
    field :user_id, :integer
    timestamps(type: :utc_datetime)
  end
end

defmodule Course.Ch08.Tag do
  use Ecto.Schema

  schema "tags" do
    field :name, :string
    field :user_id, :integer
  end
end

defmodule Course.Ch08.Note do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notes" do
    field :title, :string
    field :body, :string, default: ""
    field :lock_version, :integer, default: 1
    field :notebook_id, :integer
    field :user_id, :integer

    many_to_many :tags, Course.Ch08.Tag,
      join_through: "notes_tags",
      join_keys: [note_id: :id, tag_id: :id],
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc "Casts a note's title and body; the title is required."
  @spec changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def changeset(note, attrs) do
    note
    |> cast(attrs, [:title, :body])
    |> validate_required([:title])
    |> validate_length(:title, max: 160)
  end
end
