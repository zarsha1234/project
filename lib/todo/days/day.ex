defmodule Todo.Days.Day do
  use Ecto.Schema
  import Ecto.Changeset

  schema "days" do
    field :names, :string
    field :weather, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(day, attrs) do
    day
    |> cast(attrs, [:names, :weather])
    |> validate_required([:names, :weather])
  end
end
