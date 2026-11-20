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

defmodule Support.Migrations.Ch08 do
  use Ecto.Migration

  @fts [
    {"""
     CREATE VIRTUAL TABLE notes_fts USING fts5(title, body, content='notes', content_rowid='id')
     """, "DROP TABLE notes_fts"},
    {"""
     CREATE TRIGGER notes_fts_insert AFTER INSERT ON notes BEGIN
       INSERT INTO notes_fts(rowid, title, body) VALUES (new.id, new.title, new.body);
     END
     """, "DROP TRIGGER notes_fts_insert"},
    {"""
     CREATE TRIGGER notes_fts_delete AFTER DELETE ON notes BEGIN
       INSERT INTO notes_fts(notes_fts, rowid, title, body)
       VALUES ('delete', old.id, old.title, old.body);
     END
     """, "DROP TRIGGER notes_fts_delete"},
    {"""
     CREATE TRIGGER notes_fts_update AFTER UPDATE ON notes BEGIN
       INSERT INTO notes_fts(notes_fts, rowid, title, body)
       VALUES ('delete', old.id, old.title, old.body);
       INSERT INTO notes_fts(rowid, title, body) VALUES (new.id, new.title, new.body);
     END
     """, "DROP TRIGGER notes_fts_update"}
  ]

  def change do
    create table(:users) do
      add :email, :string, null: false
    end

    create table(:notebooks) do
      add :name, :string, null: false
      add :user_id, references(:users), null: false
      timestamps(type: :utc_datetime)
    end

    create table(:notes) do
      add :title, :string, null: false
      add :body, :string, null: false, default: ""
      add :lock_version, :integer, null: false, default: 1
      add :notebook_id, references(:notebooks), null: false
      add :user_id, references(:users), null: false
      timestamps(type: :utc_datetime)
    end

    create table(:tags) do
      add :name, :string, null: false
      add :user_id, references(:users), null: false
    end

    create unique_index(:tags, [:user_id, :name])

    create table(:notes_tags, primary_key: false) do
      add :note_id, references(:notes, on_delete: :delete_all), null: false, primary_key: true
      add :tag_id, references(:tags, on_delete: :delete_all), null: false, primary_key: true
    end

    Enum.each(@fts, fn {up, down} -> execute(up, down) end)
  end
end

defmodule Support.Migrations do
  alias Support.Repo

  @migrations [{6, Support.Migrations.Ch06}, {8, Support.Migrations.Ch08}]

  @spec run!() :: :ok
  def run! do
    _ = Ecto.Migrator.run(Repo, @migrations, :up, all: true, log: false)
    :ok
  end
end
