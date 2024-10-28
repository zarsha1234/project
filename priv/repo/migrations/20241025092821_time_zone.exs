defmodule Todo.Repo.Migrations.TimeZone do
  use Ecto.Migration

  def change do
    alter table(:path) do
    add :time_zone, :string
    add :time_format, :string
    add :date_format, :string
  end
end
end
