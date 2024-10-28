defmodule Todo.Student do
  use Ecto.Schema
  import Ecto.Changeset

  schema "students" do
    field :name, :string
    field :age, :integer
    field :class, :string
    field :subject, :string
    field :email, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(student, attrs) do
    student
    |> cast(attrs, [:name, :age, :class, :subject, :email])
    |> validate_required([:name, :age, :class, :subject, :email])
  end
end
