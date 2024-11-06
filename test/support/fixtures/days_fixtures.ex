defmodule Todo.DaysFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Todo.Days` context.
  """

  @doc """
  Generate a day.
  """
  def day_fixture(attrs \\ %{}) do
    {:ok, day} =
      attrs
      |> Enum.into(%{
        names: "some names",
        weather: "some weather"
      })
      |> Todo.Days.create_day()

    day
  end
end
