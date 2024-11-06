defmodule TodoWeb.DayLive.FormComponent do
  use TodoWeb, :live_component

  alias Todo.Days

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage day records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="day-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:names]} type="text" label="Names" />
        <.input field={@form[:weather]} type="text" label="Weather" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Day</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{day: day} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Days.change_day(day))
     end)}
  end

  @impl true
  def handle_event("validate", %{"day" => day_params}, socket) do
    changeset = Days.change_day(socket.assigns.day, day_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"day" => day_params}, socket) do
    save_day(socket, socket.assigns.action, day_params)
  end

  defp save_day(socket, :edit, day_params) do
    case Days.update_day(socket.assigns.day, day_params) do
      {:ok, day} ->
        notify_parent({:saved, day})

        {:noreply,
         socket
         |> put_flash(:info, "Day updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_day(socket, :new, day_params) do
    case Days.create_day(day_params) do
      {:ok, day} ->
        notify_parent({:saved, day})

        {:noreply,
         socket
         |> put_flash(:info, "Day created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
