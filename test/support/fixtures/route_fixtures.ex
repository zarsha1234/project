defmodule Todo.RouteFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Todo.Route` context.
  """

  def unique_path_email, do: "path#{System.unique_integer()}@example.com"
  def valid_path_password, do: "hello world!"

  def valid_path_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_path_email(),
      password: valid_path_password()
    })
  end

  def path_fixture(attrs \\ %{}) do
    {:ok, path} =
      attrs
      |> valid_path_attributes()
      |> Todo.Route.register_path()

    path
  end

  def extract_path_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
