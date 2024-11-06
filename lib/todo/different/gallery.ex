defmodule Todo.Different.Gallery do
  use Ecto.Schema
  import Ecto.Changeset

  schema "gallerys" do
    field :name, :string
    field :image, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(gallery, attrs) do
    gallery
    |> cast(attrs, [:name, :image])
    |> validate_required([:name, :image])
  end
end
