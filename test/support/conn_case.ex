defmodule TodoWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use TodoWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint TodoWeb.Endpoint

      use TodoWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import TodoWeb.ConnCase
    end
  end

  setup tags do
    Todo.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in path.

      setup :register_and_log_in_path

  It stores an updated connection and a registered path in the
  test context.
  """
  def register_and_log_in_path(%{conn: conn}) do
    path = Todo.RouteFixtures.path_fixture()
    %{conn: log_in_path(conn, path), path: path}
  end

  @doc """
  Logs the given `path` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_path(conn, path) do
    token = Todo.Route.generate_path_session_token(path)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:path_token, token)
  end
end
