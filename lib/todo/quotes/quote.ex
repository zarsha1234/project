defmodule Todo.Quotes.Quote do
  use Ecto.Schema
  import Ecto.Changeset

  schema "quotes" do
    field :author, :string
    field :source, :string
    field :quote, :string

    timestamps(type: :utc_datetime)

  end

  @doc false
  def changeset(quote, attrs) do
    quote
    |> cast(attrs, [:quote, :author, :source])
    |> validate_required([:quote, :author, :source])
    # > unique_constraint(:quote, name: :index_for_duplicate_quotes)
  end
end
