defmodule TodoWeb.SuchLive.Show do
  use TodoWeb, :live_view

  alias Todo.Chat

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:such, Chat.get_such!(id))}
  end

  defp page_title(:show), do: "Show Such"
  defp page_title(:edit), do: "Edit Such"
end
