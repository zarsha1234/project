defmodule Todo.Repo.Migrations.CreateDays do
  use Ecto.Migration

  def change do
    create table(:days) do
      add :names, :string
      add :weather, :string

      timestamps(type: :utc_datetime)
    end
  end
end
