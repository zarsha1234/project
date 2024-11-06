defmodule Todo.Repo.Migrations.CreateGallerys do
  use Ecto.Migration

  def change do
    create table(:gallerys) do
      add :name, :string
      add :image, :string

      timestamps(type: :utc_datetime)
    end
  end
end
