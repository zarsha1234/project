defmodule Todo.Chat.Such do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :name, :string
    field :content, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(such, attrs) do
    such
    |> cast(attrs, [:name, :content])
    |> validate_required([:name, :content])
  end

 def create_message(attrs) do
    %Todo.Chat.Such{}
    |> changeset(attrs)
    |> Repo.insert()
  end
end
