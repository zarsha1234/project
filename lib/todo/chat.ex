defmodule Todo.Chat do
  @moduledoc """
  The Chat context.
  """

  import Ecto.Query, warn: false
  alias Todo.Repo

  alias Todo.Chat.Such

  @doc """
  Returns the list of messages.

  ## Examples

      iex> list_messages()
      [%Such{}, ...]

  """
   def list_messages do
    Repo.all(Such)
  end

  @doc """
  Gets a single such.

  Raises `Ecto.NoResultsError` if the Such does not exist.

  ## Examples

      iex> get_such!(123)
      %Such{}

      iex> get_such!(456)
      ** (Ecto.NoResultsError)

  """
  def get_such!(id), do: Repo.get!(Such, id)

  @doc """
  Creates a such.

  ## Examples

      iex> create_such(%{field: value})
      {:ok, %Such{}}

      iex> create_such(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_such(attrs \\ %{}) do
    %Such{}
    |> Such.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a such.

  ## Examples

      iex> update_such(such, %{field: new_value})
      {:ok, %Such{}}

      iex> update_such(such, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_such(%Such{} = such, attrs) do
    such
    |> Such.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a such.

  ## Examples

      iex> delete_such(such)
      {:ok, %Such{}}

      iex> delete_such(such)
      {:error, %Ecto.Changeset{}}

  """
  def delete_such(%Such{} = such) do
    Repo.delete(such)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking such changes.

  ## Examples

      iex> change_such(such)
      %Ecto.Changeset{data: %Such{}}

  """
  def change_such(%Such{} = such, attrs \\ %{}) do
    Such.changeset(such, attrs)
  end
end
