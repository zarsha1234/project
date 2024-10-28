defmodule Todo.Class do
  use Ecto.Schema
  import Ecto.Changeset

  schema "class" do
    field :name, :string
    field :class, :string
    field :age, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(class, attrs) do
    class
    |> cast(attrs, [:name, :class, :age])
    |> validate_required([:name, :class, :age])
  end
end
