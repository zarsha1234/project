defmodule TodoWeb.PathConfirmationLiveTest do
  use TodoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Todo.RouteFixtures

  alias Todo.Route
  alias Todo.Repo

  setup do
    %{path: path_fixture()}
  end

  describe "Confirm path" do
    test "renders confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/path/confirm/some-token")
      assert html =~ "Confirm Account"
    end

    test "confirms the given token once", %{conn: conn, path: path} do
      token =
        extract_path_token(fn url ->
          Route.deliver_path_confirmation_instructions(path, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/path/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Path confirmed successfully"

      assert Route.get_path!(path.id).confirmed_at
      refute get_session(conn, :path_token)
      assert Repo.all(Route.PathToken) == []

      # when not logged in
      {:ok, lv, _html} = live(conn, ~p"/path/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Path confirmation link is invalid or it has expired"

      # when logged in
      conn =
        build_conn()
        |> log_in_path(path)

      {:ok, lv, _html} = live(conn, ~p"/path/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result
      refute Phoenix.Flash.get(conn.assigns.flash, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, path: path} do
      {:ok, lv, _html} = live(conn, ~p"/path/confirm/invalid-token")

      {:ok, conn} =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Path confirmation link is invalid or it has expired"

      refute Route.get_path!(path.id).confirmed_at
    end
  end
end
