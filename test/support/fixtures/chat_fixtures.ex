defmodule Todo.ChatFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Todo.Chat` context.
  """

  @doc """
  Generate a such.
  """
  def such_fixture(attrs \\ %{}) do
    {:ok, such} =
      attrs
      |> Enum.into(%{
        content: "some content",
        name: "some name"
      })
      |> Todo.Chat.create_such()

    such
  end
end
