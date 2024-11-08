defmodule TodoWeb.Router do
  use TodoWeb, :router

  import TodoWeb.PathAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TodoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_path
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TodoWeb do
    pipe_through :browser

    get "/home", PageController, :home

    live "/users", UserLive.Index, :index
    live "/users/new", UserLive.Index, :new
    live "/users/:id/edit", UserLive.Index, :edit
    live "/users/:id", UserLive.Show, :show
    live "/users/:id/show/edit", UserLive.Show, :edit
    live "/chat", ChatLive.Index
    live "/todos", TodoLive, :index
    live "/candy", CandyLive, :index
    live "/days", DayLive.Index, :index
    live "/days/new", DayLive.Index, :new
    live "/days/:id/edit", DayLive.Index, :edit

    live "/days/:id", DayLive.Show, :show
    live "/days/:id/show/edit", DayLive.Show, :edit
    live "/gallerys", GalleryLive.Index, :index
    live "/gallerys/new", GalleryLive.Index, :new
    live "/gallerys/:id/edit", GalleryLive.Index, :edit

    live "/gallerys/:id", GalleryLive.Show, :show
    live "/gallerys/:id/show/edit", GalleryLive.Show, :edit

    live "/messages", SuchLive.Index, :index
    live "/messages/new", SuchLive.Index, :new
    live "/messages/:id/edit", SuchLive.Index, :edit

    live "/messages/:id", SuchLive.Show, :show
    live "/messages/:id/show/edit", SuchLive.Show, :edit




  end




  # Other scopes may use custom stacks.
  #scope "/dev", TodoWeb do
   #pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:todo, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/api", TodoWeb do
      pipe_through :api
      get "/quotes", QuotesController, :index
      get "/quotes/random", QuotesController, :show
    end

      live_dashboard "/dashboard", metrics: TodoWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end

  ## Authentication routes

  scope "/", TodoWeb do
    pipe_through [:browser, :redirect_if_path_is_authenticated]

    live_session :redirect_if_path_is_authenticated,
      on_mount: [{TodoWeb.PathAuth, :redirect_if_path_is_authenticated}] do
      live "/path/register", PathRegistrationLive, :new
      live "/path/log_in", PathLoginLive, :new
      live "/path/reset_password", PathForgotPasswordLive, :new
      live "/path/reset_password/:token", PathResetPasswordLive, :edit


    end

    post "/path/log_in", PathSessionController, :create
  end

  scope "/", TodoWeb do
    pipe_through [:browser, :require_authenticated_path]

    live_session :require_authenticated_path,
      on_mount: [{TodoWeb.PathAuth, :ensure_authenticated}] do
      live "/path/settings", PathSettingsLive, :edit
      live "/path/settings/confirm_email/:token", PathSettingsLive, :confirm_email
    end
  end

  scope "/", TodoWeb do
    pipe_through [:browser]

    delete "/path/log_out", PathSessionController, :delete

    live_session :current_path,
      on_mount: [{TodoWeb.PathAuth, :mount_current_path}] do
      live "/path/confirm/:token", PathConfirmationLive, :edit
      live "/path/confirm", PathConfirmationInstructionsLive, :new
    end
  end
end
