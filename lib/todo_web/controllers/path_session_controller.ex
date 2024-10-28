defmodule TodoWeb.PathSessionController do
  use TodoWeb, :controller

  alias Todo.Route
  alias TodoWeb.PathAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:path_return_to, ~p"/path/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"path" => path_params}, info) do
    %{"email" => email, "password" => password} = path_params

    if path = Route.get_path_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> PathAuth.log_in_path(path, path_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/path/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> PathAuth.log_out_path()
  end
end
