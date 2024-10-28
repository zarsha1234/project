defmodule TodoWeb.PathAuthTest do
  use TodoWeb.ConnCase, async: true

  alias Phoenix.LiveView
  alias Todo.Route
  alias TodoWeb.PathAuth
  import Todo.RouteFixtures

  @remember_me_cookie "_todo_web_path_remember_me"

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, TodoWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{path: path_fixture(), conn: conn}
  end

  describe "log_in_path/3" do
    test "stores the path token in the session", %{conn: conn, path: path} do
      conn = PathAuth.log_in_path(conn, path)
      assert token = get_session(conn, :path_token)
      assert get_session(conn, :live_socket_id) == "path_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == ~p"/"
      assert Route.get_path_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, path: path} do
      conn = conn |> put_session(:to_be_removed, "value") |> PathAuth.log_in_path(path)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, path: path} do
      conn = conn |> put_session(:path_return_to, "/hello") |> PathAuth.log_in_path(path)
      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, path: path} do
      conn = conn |> fetch_cookies() |> PathAuth.log_in_path(path, %{"remember_me" => "true"})
      assert get_session(conn, :path_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :path_token)
      assert max_age == 5_184_000
    end
  end

  describe "logout_path/1" do
    test "erases session and cookies", %{conn: conn, path: path} do
      path_token = Route.generate_path_session_token(path)

      conn =
        conn
        |> put_session(:path_token, path_token)
        |> put_req_cookie(@remember_me_cookie, path_token)
        |> fetch_cookies()
        |> PathAuth.log_out_path()

      refute get_session(conn, :path_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
      refute Route.get_path_by_session_token(path_token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "path_sessions:abcdef-token"
      TodoWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> PathAuth.log_out_path()

      assert_receive %Phoenix.Socket.Broadcast{event: "disconnect", topic: ^live_socket_id}
    end

    test "works even if path is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> PathAuth.log_out_path()
      refute get_session(conn, :path_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
    end
  end

  describe "fetch_current_path/2" do
    test "authenticates path from session", %{conn: conn, path: path} do
      path_token = Route.generate_path_session_token(path)
      conn = conn |> put_session(:path_token, path_token) |> PathAuth.fetch_current_path([])
      assert conn.assigns.current_path.id == path.id
    end

    test "authenticates path from cookies", %{conn: conn, path: path} do
      logged_in_conn =
        conn |> fetch_cookies() |> PathAuth.log_in_path(path, %{"remember_me" => "true"})

      path_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> PathAuth.fetch_current_path([])

      assert conn.assigns.current_path.id == path.id
      assert get_session(conn, :path_token) == path_token

      assert get_session(conn, :live_socket_id) ==
               "path_sessions:#{Base.url_encode64(path_token)}"
    end

    test "does not authenticate if data is missing", %{conn: conn, path: path} do
      _ = Route.generate_path_session_token(path)
      conn = PathAuth.fetch_current_path(conn, [])
      refute get_session(conn, :path_token)
      refute conn.assigns.current_path
    end
  end

  describe "on_mount :mount_current_path" do
    test "assigns current_path based on a valid path_token", %{conn: conn, path: path} do
      path_token = Route.generate_path_session_token(path)
      session = conn |> put_session(:path_token, path_token) |> get_session()

      {:cont, updated_socket} =
        PathAuth.on_mount(:mount_current_path, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_path.id == path.id
    end

    test "assigns nil to current_path assign if there isn't a valid path_token", %{conn: conn} do
      path_token = "invalid_token"
      session = conn |> put_session(:path_token, path_token) |> get_session()

      {:cont, updated_socket} =
        PathAuth.on_mount(:mount_current_path, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_path == nil
    end

    test "assigns nil to current_path assign if there isn't a path_token", %{conn: conn} do
      session = conn |> get_session()

      {:cont, updated_socket} =
        PathAuth.on_mount(:mount_current_path, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_path == nil
    end
  end

  describe "on_mount :ensure_authenticated" do
    test "authenticates current_path based on a valid path_token", %{conn: conn, path: path} do
      path_token = Route.generate_path_session_token(path)
      session = conn |> put_session(:path_token, path_token) |> get_session()

      {:cont, updated_socket} =
        PathAuth.on_mount(:ensure_authenticated, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_path.id == path.id
    end

    test "redirects to login page if there isn't a valid path_token", %{conn: conn} do
      path_token = "invalid_token"
      session = conn |> put_session(:path_token, path_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: TodoWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = PathAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_path == nil
    end

    test "redirects to login page if there isn't a path_token", %{conn: conn} do
      session = conn |> get_session()

      socket = %LiveView.Socket{
        endpoint: TodoWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = PathAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_path == nil
    end
  end

  describe "on_mount :redirect_if_path_is_authenticated" do
    test "redirects if there is an authenticated  path ", %{conn: conn, path: path} do
      path_token = Route.generate_path_session_token(path)
      session = conn |> put_session(:path_token, path_token) |> get_session()

      assert {:halt, _updated_socket} =
               PathAuth.on_mount(
                 :redirect_if_path_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end

    test "doesn't redirect if there is no authenticated path", %{conn: conn} do
      session = conn |> get_session()

      assert {:cont, _updated_socket} =
               PathAuth.on_mount(
                 :redirect_if_path_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end
  end

  describe "redirect_if_path_is_authenticated/2" do
    test "redirects if path is authenticated", %{conn: conn, path: path} do
      conn = conn |> assign(:current_path, path) |> PathAuth.redirect_if_path_is_authenticated([])
      assert conn.halted
      assert redirected_to(conn) == ~p"/"
    end

    test "does not redirect if path is not authenticated", %{conn: conn} do
      conn = PathAuth.redirect_if_path_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_path/2" do
    test "redirects if path is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> PathAuth.require_authenticated_path([])
      assert conn.halted

      assert redirected_to(conn) == ~p"/path/log_in"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must log in to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | path_info: ["foo"], query_string: ""}
        |> fetch_flash()
        |> PathAuth.require_authenticated_path([])

      assert halted_conn.halted
      assert get_session(halted_conn, :path_return_to) == "/foo"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar=baz"}
        |> fetch_flash()
        |> PathAuth.require_authenticated_path([])

      assert halted_conn.halted
      assert get_session(halted_conn, :path_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar", method: "POST"}
        |> fetch_flash()
        |> PathAuth.require_authenticated_path([])

      assert halted_conn.halted
      refute get_session(halted_conn, :path_return_to)
    end

    test "does not redirect if path is authenticated", %{conn: conn, path: path} do
      conn = conn |> assign(:current_path, path) |> PathAuth.require_authenticated_path([])
      refute conn.halted
      refute conn.status
    end
  end
end
