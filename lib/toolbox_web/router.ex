defmodule ToolboxWeb.Router do
  use ToolboxWeb, :router

  import Oban.Web.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ToolboxWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :admin do
    plug :admin_basic_auth
  end

  scope "/", ToolboxWeb do
    pipe_through [:browser]

    live "/", HomeLive, private: %{seo: true}
    live "/about", AboutLive, private: %{seo: true}

    live "/packages/:name", PackageLive, private: %{seo: true}
    live "/packages/:name/:version", PackageLive
    live "/searches/:term", SearchLive

    live "/categories", CategoryIndexLive, private: %{seo: true}
    live "/categories/:permalink", CategoryLive, private: %{seo: true}
  end

  scope "/admin", ToolboxWeb do
    pipe_through [:browser, :admin]

    oban_dashboard("/oban")

    import Phoenix.LiveDashboard.Router
    live_dashboard "/dashboard", metrics: ToolboxWeb.Telemetry
  end

  defp admin_basic_auth(conn, _opts) do
    Plug.BasicAuth.basic_auth(conn, Application.fetch_env!(:toolbox, :admin_basic_auth))
  end
end
