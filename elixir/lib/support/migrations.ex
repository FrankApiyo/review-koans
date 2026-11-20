defmodule Support.Migrations.Ch06 do
  use Ecto.Migration

  def change do
    create table(:blog_users) do
      add :email, :string, null: false
      timestamps(type: :utc_datetime)
    end

    create unique_index(:blog_users, [:email])

    create table(:blog_posts) do
      add :title, :string, null: false
      add :body, :string
      add :views, :integer, null: false, default: 0
      add :user_id, references(:blog_users), null: false
      timestamps(type: :utc_datetime)
    end

    create table(:blog_comments) do
      add :body, :string, null: false
      add :post_id, references(:blog_posts), null: false
      timestamps(type: :utc_datetime)
    end
  end
end

defmodule Support.Migrations do
  alias Support.Repo

  @migrations [{6, Support.Migrations.Ch06}]

  @spec run!() :: :ok
  def run! do
    _ = Ecto.Migrator.run(Repo, @migrations, :up, all: true, log: false)
    :ok
  end
end
