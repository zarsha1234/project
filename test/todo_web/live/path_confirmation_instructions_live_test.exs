defmodule TodoWeb.PathConfirmationInstructionsLiveTest do
  use TodoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Todo.RouteFixtures

  alias Todo.Route
  alias Todo.Repo

  setup do
    %{path: path_fixture()}
  end

  describe "Resend confirmation" do
    test "renders the resend confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/path/confirm")
      assert html =~ "Resend confirmation instructions"
    end

    test "sends a new confirmation token", %{conn: conn, path: path} do
      {:ok, lv, _html} = live(conn, ~p"/path/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", path: %{email: path.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.get_by!(Route.PathToken, path_id: path.id).context == "confirm"
    end

    test "does not send confirmation token if path is confirmed", %{conn: conn, path: path} do
      Repo.update!(Route.Path.confirm_changeset(path))

      {:ok, lv, _html} = live(conn, ~p"/path/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", path: %{email: path.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      refute Repo.get_by(Route.PathToken, path_id: path.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/path/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", path: %{email: "unknown@example.com"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.all(Route.PathToken) == []
    end
  end
end
