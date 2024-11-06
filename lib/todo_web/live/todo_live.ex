
defmodule TodoWeb.TodoLive do
  use TodoWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, tasks: [], new_task: "" )}
  end
  def render(assigns) do
    ~H"""
    <h1>ZARSHA List</h1>

    <form phx-submit="validate_task">
      <input type="text" name="task" placeholder="Add a new task" value={@new_task} required />
      <button type="submit">Add</button>
    </form>

    <ul>
      <%= for task <- @tasks do %>
        <li>
          <span style={"text-decoration: #{if task.completed, do: "line-through", else: "none"};"}>
            <%= task.title %>
          </span>
          <button phx-click="complete_task" phx-value-id={task.id}>
            <%= if task.completed, do: "ok", else: "Complete" %>
          </button>
          <button phx-click="delete_task" phx-value-id={task.id}>delete</button>
        </li>
      <% end %>
    </ul>
    """
  end


  def handle_event("validate_task", %{"task" => task}, socket) do
    new_task = %{id: :erlang.unique_integer([:positive]), title: task, completed: true}
    {:noreply, assign(socket, tasks: [new_task | socket.assigns.tasks], new_task: "")}
  end

  def handle_event("complete_task", %{"id" => id}, socket) do
    tasks = Enum.map(socket.assigns.tasks, fn task ->
      if task.id == String.to_integer(id), do: %{task | completed: !task.completed}, else: task
    end)
    {:noreply, assign(socket, tasks: tasks)}
  end

  def handle_event("delete_task", %{"id" => id}, socket) do
    tasks = Enum.reject(socket.assigns.tasks, fn task -> task.id == String.to_integer(id) end)
    {:noreply, assign(socket, tasks: tasks)}
  end

end
