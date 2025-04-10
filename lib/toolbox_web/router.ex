defmodule ToolboxWeb.Router do
  use ToolboxWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ToolboxWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :basic_auth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :admin do
    plug :put_layout, html: {JustPollsWeb.Layouts, :admin}
    plug :admin_basic_auth
  end

  scope "/", ToolboxWeb do
    pipe_through :browser

    live "/", HomeLive

    live "/packages/:name", PackageLive
  end

  scope "/admin", ToolboxWeb do
    pipe_through [:browser, :admin]

    live "/", Admin.HomeLive
    live "/packages/:name", Admin.PackageLive

    import Phoenix.LiveDashboard.Router
    live_dashboard "/dashboard", metrics: ToolboxWeb.Telemetry
  end

  defp basic_auth(conn, _opts) do
    Plug.BasicAuth.basic_auth(conn, Application.fetch_env!(:toolbox, :basic_auth))
  end

  defp admin_basic_auth(conn, _opts) do
    Plug.BasicAuth.basic_auth(conn, Application.fetch_env!(:toolbox, :basic_auth))
  end
end
