defmodule Todo.Repo.Migrations.CreatePathAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:path) do
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:path, [:email])

    create table(:path_tokens) do
      add :path_id, references(:path, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:path_tokens, [:path_id])
    create unique_index(:path_tokens, [:context, :token])
  end
end
