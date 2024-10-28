defmodule Todo.Repo.Migrations.CreateStudents do
  use Ecto.Migration

  def change do
    create table(:students) do
      add :name, :string
      add :age, :integer
      add :class, :string
      add :subject, :string
      add :email, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
