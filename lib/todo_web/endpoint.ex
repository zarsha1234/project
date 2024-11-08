defmodule TodoWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :todo

  # The session will be stored in the cookie and signed,
  # meaning its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_todo_key",
    signing_salt: "x1Gq+sUd",
    same_site: "Lax"
  ]

  # Configure the LiveView socket with session options
  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]],
    pubsub_server: Todo.PubSub



  # Serve static files from the "priv/static" directory at "/"
  plug Plug.Static,
    at: "/",
    from: :todo,
    gzip: false,
    only: TodoWeb.static_paths()

  # Enable code reloading if configured for development
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :todo
  end

  # Request logging setup for LiveDashboard
  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  # Configure parsers for handling requests
  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  # Configure session storage
  plug Plug.Session, @session_options

  # Use the application router
  plug TodoWeb.Router
end
