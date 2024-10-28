defmodule TodoWeb.PathSettingsLiveTest do
  use TodoWeb.ConnCase, async: true

  alias Todo.Route
  import Phoenix.LiveViewTest
  import Todo.RouteFixtures

  describe "Settings page" do
    test "renders settings page", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_path(path_fixture())
        |> live(~p"/path/settings")

      assert html =~ "Change Email"
      assert html =~ "Change Password"
    end

    test "redirects if path is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/path/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/path/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "update email form" do
    setup %{conn: conn} do
      password = valid_path_password()
      path = path_fixture(%{password: password})
      %{conn: log_in_path(conn, path), path: path, password: password}
    end

    test "updates the path email", %{conn: conn, password: password, path: path} do
      new_email = unique_path_email()

      {:ok, lv, _html} = live(conn, ~p"/path/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => password,
          "path" => %{"email" => new_email}
        })
        |> render_submit()

      assert result =~ "A link to confirm your email"
      assert Route.get_path_by_email(path.email)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/path/settings")

      result =
        lv
        |> element("#email_form")
        |> render_change(%{
          "action" => "update_email",
          "current_password" => "invalid",
          "path" => %{"email" => "with spaces"}
        })

      assert result =~ "Change Email"
      assert result =~ "must have the @ sign and no spaces"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn, path: path} do
      {:ok, lv, _html} = live(conn, ~p"/path/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => "invalid",
          "path" => %{"email" => path.email}
        })
        |> render_submit()

      assert result =~ "Change Email"
      assert result =~ "did not change"
      assert result =~ "is not valid"
    end
  end

  describe "update password form" do
    setup %{conn: conn} do
      password = valid_path_password()
      path = path_fixture(%{password: password})
      %{conn: log_in_path(conn, path), path: path, password: password}
    end

    test "updates the path password", %{conn: conn, path: path, password: password} do
      new_password = valid_path_password()

      {:ok, lv, _html} = live(conn, ~p"/path/settings")

      form =
        form(lv, "#password_form", %{
          "current_password" => password,
          "path" => %{
            "email" => path.email,
            "password" => new_password,
            "password_confirmation" => new_password
          }
        })

      render_submit(form)

      new_password_conn = follow_trigger_action(form, conn)

      assert redirected_to(new_password_conn) == ~p"/path/settings"

      assert get_session(new_password_conn, :path_token) != get_session(conn, :path_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert Route.get_path_by_email_and_password(path.email, new_password)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/path/settings")

      result =
        lv
        |> element("#password_form")
        |> render_change(%{
          "current_password" => "invalid",
          "path" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/path/settings")

      result =
        lv
        |> form("#password_form", %{
          "current_password" => "invalid",
          "path" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })
        |> render_submit()

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
      assert result =~ "is not valid"
    end
  end

  describe "confirm email" do
    setup %{conn: conn} do
      path = path_fixture()
      email = unique_path_email()

      token =
        extract_path_token(fn url ->
          Route.deliver_path_update_email_instructions(%{path | email: email}, path.email, url)
        end)

      %{conn: log_in_path(conn, path), token: token, email: email, path: path}
    end

    test "updates the path email once", %{conn: conn, path: path, token: token, email: email} do
      {:error, redirect} = live(conn, ~p"/path/settings/confirm_email/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/path/settings"
      assert %{"info" => message} = flash
      assert message == "Email changed successfully."
      refute Route.get_path_by_email(path.email)
      assert Route.get_path_by_email(email)

      # use confirm token again
      {:error, redirect} = live(conn, ~p"/path/settings/confirm_email/#{token}")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/path/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
    end

    test "does not update email with invalid token", %{conn: conn, path: path} do
      {:error, redirect} = live(conn, ~p"/path/settings/confirm_email/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/path/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
      assert Route.get_path_by_email(path.email)
    end

    test "redirects if path is not logged in", %{token: token} do
      conn = build_conn()
      {:error, redirect} = live(conn, ~p"/path/settings/confirm_email/#{token}")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/path/log_in"
      assert %{"error" => message} = flash
      assert message == "You must log in to access this page."
    end
  end
end
