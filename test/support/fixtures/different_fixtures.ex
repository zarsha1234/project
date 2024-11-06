defmodule Todo.DifferentFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Todo.Different` context.
  """

  @doc """
  Generate a gallery.
  """
  def gallery_fixture(attrs \\ %{}) do
    {:ok, gallery} =
      attrs
      |> Enum.into(%{
        image: "some image",
        name: "some name"
      })
      |> Todo.Different.create_gallery()

    gallery
  end
end
