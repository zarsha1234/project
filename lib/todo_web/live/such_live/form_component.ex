defmodule TodoWeb.SuchLive.FormComponent do
  use TodoWeb, :live_component

  alias Todo.Chat
  alias Todo.Chat.Such

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage such records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="such-form"
        phx-target={@myself}
        phx-change="validate_message"
        phx-submit="send_message"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:content]} type="text" label="Message" />
        <:actions>
          <.button phx-disable-with="Sending...">Send</.button>
        </:actions>
      </.simple_form>

      <div id="messages">
        <%= for message <- @messages do %>
          <div class="message">
            <strong><%= message.name %>:</strong>
            <p><%= message.content %></p>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def update(%{such: such} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Chat.change_such(such))
     end)
     |> assign(:messages, [])}
  end

  @impl true
  def handle_event(
        "validate_message",
        %{"message" => %{"name" => name, "content" => content}},
        socket
      ) do
    IO.inspect({name, content}, label: "Validate Message Data")
    changeset = Chat.change_such(%Such{name: name, content: content})
    {:noreply, assign(socket, form: changeset)}
  end

  @impl true
  def handle_event(
        "send_message",
        %{"message" => %{"name" => name, "content" => content}},
        socket
      ) do

    IO.inspect({name, content}, label: "Message Data")

    case Such.create_message(%{"name" => name, "content" => content}) do
      {:ok, message} ->
        IO.inspect(message, label: "Saved Message")
        Phoenix.PubSub.broadcast(Todo.PubSub, "chat:lobby", {:new_message, message})

        {:noreply,
         assign(socket,
                messages: [message | socket.assigns.messages],
                name: "",
                content: "")}

      {:error, changeset} ->
        IO.inspect(changeset, label: "Error Creating Message")
        {:noreply, assign(socket, changeset: changeset)}
    end
  end



  defp save_such(socket, :edit, such_params) do
    case Chat.update_such(socket.assigns.such, such_params) do
      {:ok, such} ->
        notify_parent({:saved, such})

        {:noreply,
         socket
         |> put_flash(:info, "Such updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_such(socket, :new, such_params) do
    case Chat.create_such(such_params) do
      {:ok, such} ->
        notify_parent({:saved, such})

        {:noreply,
         socket
         |> put_flash(:info, "Such created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
