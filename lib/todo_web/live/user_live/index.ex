defmodule TodoWeb.UserLive.Index do
  use TodoWeb, :live_view

  alias Todo.Accounts
  alias Todo.Accounts.User

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :users, Accounts.list_users())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit User")
    |> assign(:user, Accounts.get_user!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New User")
    |> assign(:user, %User{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Users")
    |> assign(:user, nil)
  end

  @impl true
  def handle_info({TodoWeb.UserLive.FormComponent, {:saved, user}}, socket) do
    users = [user | socket.assigns.users]
    |> Enum.uniq_by(fn u -> u.id end)
    {:noreply, assign(socket, :users, users)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)
    {:ok, _} = Accounts.delete_user(user)

    updated_users = Enum.reject(socket.assigns.users, fn u -> u.id == user.id end)
    {:noreply, assign(socket, :users, updated_users)}
  end
end
