defmodule TodoWeb.GalleryLive.FormComponent do
  use TodoWeb, :live_component

  alias Todo.Different

  @impl true

  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage gallery records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="gallery-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <div>
          <label>Image</label>
          <.live_file_input upload={@uploads.image}/>
          <%= for entry <- @uploads.image.entries do %>
            <.live_img_preview entry={entry} width="75" />
            <.button
              type="button"
              phx-click="cancel-upload"
              phx-target={@myself}
              phx-value-ref={entry.ref}
            >
              cancel
            </.button>
            <div class="progress" style={"width: #{ entry.progress }%"}></div>
            <%= entry.progress %>%
          <% end %>
        </div>


        <:actions>
          <.button phx-disable-with="Saving...">Save</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end


  @impl true
  def update(%{gallery: gallery} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Different.change_gallery(gallery))
      end)
     |> assign(:uploaded_files, [])
     |> allow_upload(:image, accept: ~w(.jpg .png .jpeg), max_entries: 1)}
    end


    def handle_progress(:image, entry, socket) do
      socket =
        socket
        |> assign(:upload_progress, entry.progress)

      {:noreply, socket}
    end

     def handle_event("cancel-upload", %{"ref" => ref}, socket) do
      {:noreply, cancel_upload(socket, :image, ref)}
    end

  @impl true
  def handle_event("validate", %{"gallery" => gallery_params}, socket) do
    changeset = Different.change_gallery(socket.assigns.gallery, gallery_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"gallery" => gallery_params}, socket) do
    IO.inspect(label: "see here")
    uploaded_files =
      consume_uploaded_entries(socket, :image, fn %{path: path}, _entry ->
        dest = Path.join([:code.priv_dir(:todo), "static", "uploads", Path.basename(path)])
        File.cp!(path, dest)
        {:ok, "/uploads/" <> Path.basename(dest)}
      end)

      socket = update(socket, :uploaded_files, &(&1 ++ uploaded_files))

    new_gallery_params = Map.put(gallery_params, "image", List.first(uploaded_files))
    save_gallery(socket, socket.assigns.action, new_gallery_params)
    {:noreply, save_gallery(socket, socket.assigns.action, new_gallery_params)}
  end


  defp save_gallery(socket, :edit, gallery_params) do
    case Different.update_gallery(socket.assigns.gallery, gallery_params) do
      {:ok, gallery} ->
        notify_parent({:saved, gallery})

        {:noreply,
         socket
         |> put_flash(:info, "Gallery updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_gallery(socket, :new, gallery_params) do
    case Different.create_gallery(gallery_params) do
      {:ok, gallery} ->
        notify_parent({:saved, gallery})

        {:noreply,
         socket
         |> put_flash(:info, "Gallery created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

 defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
