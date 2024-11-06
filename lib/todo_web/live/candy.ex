defmodule TodoWeb.CandyLive do
  use TodoWeb, :live_view

  @producers [
    "Avicii",
    "Martin Garrix",
    "Don Diablo",
    "Tiesto",
    "Calvin Harris",
    "Hardwell",
    "Steve Aoki",
    "David Guetta",
    "Zedd",
    "Afrojack",
    "Dimitri Vegas & Like Mike",
    "The Chainsmokers",
    "KSHMR",
    "Oliver Heldens",
    "R3hab",
    "Lost Frequencies"
  ]

  def mount(_params, _session, socket) do
    socket = assign(socket, producers: @producers, search_results: [])
    {:ok, socket}
  end

  def handle_event("search", %{"keyword" => keyword}, socket) do
    producers_copy = socket.assigns.producers
    search_results = handle_search(producers_copy, keyword)
    {:noreply, assign(socket, search_results: search_results)}
  end

  defp handle_search(producers, keyword) do
    Enum.filter(producers, fn producer ->
      String.contains?(String.downcase(producer), String.downcase(keyword))
    end)
  end


  def render(assigns) do
    ~H"""
    <div>
      <h1>Search</h1>
      <input type="text" phx-debounce="500" phx-keyup="search" placeholder="Search for a producer..." />

      <ul>
        <%= for producer <- @search_results do %>
          <li><%= producer %></li>
        <% end %>
      </ul>

    </div>
    """
  end
end
