defmodule UnclickbaiterWeb.Router do
  use UnclickbaiterWeb, :router

  import UnclickbaiterWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {UnclickbaiterWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :browser_auth do
    plug :browser
    plug :http_basic_auth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :allow_robots do
    plug UnclickbaiterWeb.Plugs.AllowRobots
  end

  defp http_basic_auth(conn, _opts) do
    case Application.get_env(:unclickbaiter, :secrets, %{})[:http_basic] do
      %{user: user, pass: pass} ->
        Plug.BasicAuth.basic_auth(conn, username: user, password: pass)

      _ ->
        conn
    end
  end

  scope "/", UnclickbaiterWeb do
    pipe_through :browser_auth

    get "/", PageController, :home
  end

  scope "/", UnclickbaiterWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{UnclickbaiterWeb.UserAuth, :require_authenticated}] do
      live "/p", PreviewLive.Index, :index
      live "/p/new", PreviewLive.Form, :new
      live "/p/:slug/edit", PreviewLive.Form, :edit
    end
  end

  scope "/", UnclickbaiterWeb do
    pipe_through [:browser, :allow_robots]

    live "/p/:slug", PreviewLive.Show, :show
  end

  # Other scopes may use custom stacks.
  # scope "/api", UnclickbaiterWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:unclickbaiter, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: UnclickbaiterWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/auth", UnclickbaiterWeb do
    pipe_through :browser

    get "/google", GoogleAuthController, :request
    get "/google/callback", GoogleAuthController, :callback
  end

  scope "/", UnclickbaiterWeb do
    pipe_through :browser

    delete "/log-out", GoogleAuthController, :delete
  end
end
