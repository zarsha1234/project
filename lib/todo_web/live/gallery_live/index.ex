defmodule TodoWeb.GalleryLive.Index do
  use TodoWeb, :live_view

  alias Todo.Different
  alias Todo.Different.Gallery

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :gallerys, Different.list_gallerys())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Gallery")
    |> assign(:gallery, Different.get_gallery!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Gallery")
    |> assign(:gallery, %Gallery{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Gallerys")
    |> assign(:gallery, nil)
  end

  @impl true
  def handle_info({TodoWeb.GalleryLive.FormComponent, {:saved, gallery}}, socket) do
    {:noreply, stream_insert(socket, :gallerys, gallery)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    gallery = Different.get_gallery!(id)
    {:ok, _} = Different.delete_gallery(gallery)

    {:noreply, stream_delete(socket, :gallerys, gallery)}
  end
end
