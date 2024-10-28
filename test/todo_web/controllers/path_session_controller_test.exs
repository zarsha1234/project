defmodule TodoWeb.PathSessionControllerTest do
  use TodoWeb.ConnCase, async: true

  import Todo.RouteFixtures

  setup do
    %{path: path_fixture()}
  end

  describe "POST /path/log_in" do
    test "logs the path in", %{conn: conn, path: path} do
      conn =
        post(conn, ~p"/path/log_in", %{
          "path" => %{"email" => path.email, "password" => valid_path_password()}
        })

      assert get_session(conn, :path_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ path.email
      assert response =~ ~p"/path/settings"
      assert response =~ ~p"/path/log_out"
    end

    test "logs the path in with remember me", %{conn: conn, path: path} do
      conn =
        post(conn, ~p"/path/log_in", %{
          "path" => %{
            "email" => path.email,
            "password" => valid_path_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_todo_web_path_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "logs the path in with return to", %{conn: conn, path: path} do
      conn =
        conn
        |> init_test_session(path_return_to: "/foo/bar")
        |> post(~p"/path/log_in", %{
          "path" => %{
            "email" => path.email,
            "password" => valid_path_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "login following registration", %{conn: conn, path: path} do
      conn =
        conn
        |> post(~p"/path/log_in", %{
          "_action" => "registered",
          "path" => %{
            "email" => path.email,
            "password" => valid_path_password()
          }
        })

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Account created successfully"
    end

    test "login following password update", %{conn: conn, path: path} do
      conn =
        conn
        |> post(~p"/path/log_in", %{
          "_action" => "password_updated",
          "path" => %{
            "email" => path.email,
            "password" => valid_path_password()
          }
        })

      assert redirected_to(conn) == ~p"/path/settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Password updated successfully"
    end

    test "redirects to login page with invalid credentials", %{conn: conn} do
      conn =
        post(conn, ~p"/path/log_in", %{
          "path" => %{"email" => "invalid@email.com", "password" => "invalid_password"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/path/log_in"
    end
  end

  describe "DELETE /path/log_out" do
    test "logs the path out", %{conn: conn, path: path} do
      conn = conn |> log_in_path(path) |> delete(~p"/path/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :path_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the path is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/path/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :path_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
