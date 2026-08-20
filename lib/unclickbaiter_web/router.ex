defmodule UnclickbaiterWeb.Router do
  use UnclickbaiterWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {UnclickbaiterWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :http_basic_auth
  end

  pipeline :api do
    plug :accepts, ["json"]
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
    pipe_through :browser

    get "/", PageController, :home

    live "/sites", SiteLive.Index, :index
    live "/sites/new", SiteLive.Form, :new
    live "/sites/:id", SiteLive.Show, :show
    live "/sites/:id/edit", SiteLive.Form, :edit
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
end
