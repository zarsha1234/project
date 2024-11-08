defmodule TodoWeb.SuchLive.Index do
  use TodoWeb, :live_view

  alias Todo.Chat
  alias Todo.Chat.Such

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Todo.PubSub, "chat:lobby")
    end
    messages = Chat.list_messages()
    {:ok, assign(socket, messages: messages, name: "", content: "")}
  end

 def handle_info({:new_message, %{name: name, content: content}}, socket) do
    {:noreply, update(socket, :messages, fn messages -> [%{name: name, content: content} | messages] end)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Such")
    |> assign(:such, Chat.get_such!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title,"New")
    |> assign(:such, %Such{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Messages")
    |> assign(:such, nil)
  end

  @impl true
  def handle_info({TodoWeb.SuchLive.FormComponent, {:saved, such}}, socket) do
    {:noreply, stream_insert(socket, :messages, such)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    such = Chat.get_such!(id)
    {:ok, _} = Chat.delete_such(such)

    {:noreply, stream_delete(socket, :messages, such)}
  end
end
