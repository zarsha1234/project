defmodule TodoWeb.PathSettingsLive do
  use TodoWeb, :live_view
  alias Todo.Route
  alias Todo.Repo
  alias Todo.Route.Path

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Account Settings
      <:subtitle>Manage your account email address and password settings</:subtitle>
    </.header>

    <div class="space-y-12 divide-y"
      <div>
        <.simple_form
          for={@email_form}
          id="email_form"
          phx-submit="update_email"
          phx-change="validate_email"
        >
          <.input field={@email_form[:email]} type="email" label="Email" required />
          <.input
            field={@email_form[:current_password]}
            name="current_password"
            id="current_password_for_email"
            type="password"
            label="Current password"
            value={@email_form_current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Email</.button>
          </:actions>
        </.simple_form>
      </div>

        <.simple_form
          for={@password_form}
          id="password_form"
          action={~p"/path/log_in?_action=password_updated"}
          method="post"
          phx-change="validate_password"
          phx-submit="update_password"
          phx-trigger-action={@trigger_submit}
        >
          <input
            name={@password_form[:email].name}
            type="hidden"
            id="hidden_path_email"
            value={@current_email}
          />
          <.input field={@password_form[:password]} type="password" label="New password" required />
          <.input
            field={@password_form[:password_confirmation]}
            type="password"
            label="Confirm new password"
          />
          <.input
            field={@password_form[:current_password]}
            name="current_password"
            type="password"
            label="Current password"
            id="current_password_for_password"
            value={@current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Password</.button>
       </:actions>
        </.simple_form>
        <div>

        <.simple_form
          for={@time_form}
          id="time_zone_form"
          phx-submit="save_time_zone"
          phx-change="validate_time_zone"
        >

        <.input field={@time_form[:time_zone]} type="select" label="Time Zone" required options={@time_zone_options} />
         <.input field={@time_form[:time_format]} type="select" label="Time Format" required options={@time_format_options} />
         <.input field={@time_form[:date_format]} type="select" label="Date Format" required options={@date_format_options} />
          <:actions>

        <p>Current Time: <%= @current_time %></p>
            <.button phx-disable-with="Saving...">Save</.button>

          </:actions>
        </.simple_form>
      </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Route.update_path_email(socket.assigns.current_path, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/path/settings")}
  end

  def mount(_params, _session, socket) do
    path = socket.assigns.current_path
    email_changeset = Route.change_path_email(path)
    password_changeset = Route.change_path_password(path)
    time_changeset = Path.time_changeset(path)
    path_time_zone = socket.assigns.current_path.time_zone || "UTC"
    path_time_format = socket.assigns.current_path.time_format ||  "12 hours"
    path_date_format = socket.assigns.current_path.date_format || "%d-%m-%y"


 time_zone_options = Tzdata.zone_list() |> IO.inspect()

 time_format_options =
 [
     {"12-hour (AM/PM)", "%I:%M %p"},
     {"12-hour (am/pm)", "%I:%M %P"} ,
     {"24-hour", "%H:%M"}
 ]

   date_format_options = [
     {"DD/MM/YYYY", "%d/%m/%Y"},
     {"MM/DD/YYYY", "%m/%d/%Y"},
     {"YYYY-MM-DD", "%Y-%m-%d"}
   ]


    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, path.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:time_form, to_form(time_changeset))
      |> assign(:time_zone_options, time_zone_options)
      |> assign(:time_format_options, time_format_options)
      |> assign(:date_format_options, date_format_options)
      |> assign(:trigger_submit, false)
      |> assign(:current_time, get_current_time(path))
      |> assign(:path_time_zone, path_time_zone)
      |> assign(:path_time_format, path_time_format)
      |> assign(:pah_date_format, path_date_format)
IO.inspect(get_current_time(path))
    {:ok, socket}
  end

  defp get_current_time(path) do
    time_zone =  path.time_zone || "Etc/UTC"
    time_format = path.time_format || ""
    date_format = path.date_format || ""
IO.inspect(time_zone)

    {:ok, now} = DateTime.shift_zone(DateTime.utc_now(), time_zone)

    combined_format = date_format <> " " <> time_format
    Calendar.strftime(now, combined_format)
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "path" => path_params} = params

    email_form =
      socket.assigns.current_path
      |> Route.change_path_email(path_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "path" => path_params} = params
    path = socket.assigns.current_path

    case Route.apply_path_email(path, password, path_params) do
      {:ok, applied_path} ->
        Route.deliver_path_update_email_instructions(
          applied_path,
          path.email,
          &url(~p"/path/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "path" => path_params} = params

    password_form =
      socket.assigns.current_path
      |> Route.change_path_password(path_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "path" => path_params} = params
    path = socket.assigns.current_path

    case Route.update_path_password(path, password, path_params) do
      {:ok, path} ->
        password_form =
          path
          |> Route.change_path_password(path_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

   def handle_event("validate_time_zone", %{"path" => params}, socket) do

    time_zone_form =
       socket.assigns.current_path
       |> Route.change_path_time(params)

       |> to_form()
       {:noreply, assign(socket, :time_form, time_zone_form)}
    end


def handle_event("save_time_zone", %{"path" => params}, socket) do
  changeset = socket.assigns.current_path
  |> Route.change_path_time(params)

  case Repo.update(changeset) do
    {:ok, updated_path} ->
      socket =
        socket
        |> assign(
          current_path: updated_path,
          time_form: to_form(Route.change_path_time(updated_path)),
          path_time_zone: updated_path.time_zone,
          path_time_format: updated_path.time_format,
          path_date_format: updated_path.date_format,
          current_time: get_current_time(updated_path)
        )
        |> put_flash( :info ,"hurrah!")
   {:noreply, socket}

    {:error, changeset} ->
      {:noreply, socket |> put_flash(:error, "So Sad.")}
  end
end
end
