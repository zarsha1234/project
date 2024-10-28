defmodule TodoWeb.PathForgotPasswordLiveTest do
  use TodoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Todo.RouteFixtures

  alias Todo.Route
  alias Todo.Repo

  describe "Forgot password page" do
    test "renders email page", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/path/reset_password")

      assert html =~ "Forgot your password?"
      assert has_element?(lv, ~s|a[href="#{~p"/path/register"}"]|, "Register")
      assert has_element?(lv, ~s|a[href="#{~p"/path/log_in"}"]|, "Log in")
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_path(path_fixture())
        |> live(~p"/path/reset_password")
        |> follow_redirect(conn, ~p"/")

      assert {:ok, _conn} = result
    end
  end

  describe "Reset link" do
    setup do
      %{path: path_fixture()}
    end

    test "sends a new reset password token", %{conn: conn, path: path} do
      {:ok, lv, _html} = live(conn, ~p"/path/reset_password")

      {:ok, conn} =
        lv
        |> form("#reset_password_form", path: %{"email" => path.email})
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"

      assert Repo.get_by!(Route.PathToken, path_id: path.id).context ==
               "reset_password"
    end

    test "does not send reset password token if email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/path/reset_password")

      {:ok, conn} =
        lv
        |> form("#reset_password_form", path: %{"email" => "unknown@example.com"})
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"
      assert Repo.all(Route.PathToken) == []
    end
  end
end
