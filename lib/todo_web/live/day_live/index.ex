defmodule TodoWeb.DayLive.Index do
  use TodoWeb, :live_view

  alias Todo.Days
  alias Todo.Days.Day
  alias Todo.Repo
  import Ecto.Query

  @impl true
def mount(_params, _session, socket) do
  days = Days.list_days()
  {:ok, assign(socket, days: days, search_keyword: "")}
end


  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("search", %{"keyword" => keyword}, socket) do
    search_term = "%#{keyword}%"
  results = from(d in Day, where: ilike(d.names, ^search_term))
              |> Repo.all()
   IO.inspect(results, label: "Search Results")
    {:noreply, assign(socket, days: results, search_keyword: keyword)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Day")
    |> assign(:day, Days.get_day!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Day")
    |> assign(:day, %Day{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Days")
    |> assign(:day, nil)
  end

  @impl true
  def handle_info({TodoWeb.DayLive.FormComponent, {:saved, day}}, socket) do
    {:noreply, stream_insert(socket, :days, day)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    day = Days.get_day!(id)
    {:ok, _} = Days.delete_day(day)

    {:noreply, stream_delete(socket, :days, day)}
  end
end
