defmodule Todo.Repo.Migrations.CreateClass do
  use Ecto.Migration

  def change do
    create table(:class) do
      add :name, :string
      add :class, :string
      add :age, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
