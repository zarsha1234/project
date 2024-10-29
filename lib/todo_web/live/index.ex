defmodule TodoWeb.ChatLive.Index do
  use TodoWeb, :live_view

  def mount(_params, _session, socket) do
    if connected?(socket) do
    TodoWeb.Endpoint.subscribe(topic)
    end
    {:ok, assign(socket, username: username(), messages: [])}
  end

  def handle_info(%{event: "message", payload: message}, socket) do
    {:noreply, assign(socket, messages: socket.assigns.messages ++ [message])}
end

  def handle_event("send", %{"text" => text}, socket) do
    TodoWeb.Endpoint.broadcast(topic(), "message", %{text: text, name: socket.assigns.username})
    {:noreply, socket}
  end
  defp username do
    "User #{:rand.uniform(100)}"
  end

  defp topic do
    "chat"
  end
end
