defmodule ToolboxWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use ToolboxWeb, :controller
      use ToolboxWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths, do: ~w(assets fonts images files robots.txt sitemap.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: ToolboxWeb.Layouts]

      import Plug.Conn
      use Gettext, backend: ToolboxWeb.Gettext

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {ToolboxWeb.Layouts, :app}

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # HTML escaping functionality
      import Phoenix.HTML
      # Core UI components and translation
      import ToolboxWeb.CoreComponents
      import ToolboxWeb.HelperComponents
      use Gettext, backend: ToolboxWeb.Gettext

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(verified_routes())

      def humanized_number(number) do
        Toolbox.Number.to_human(number)
      end

      def humanized_datetime(datetime) when is_binary(datetime) do
        Calendar.strftime(
          NaiveDateTime.from_iso8601!(datetime),
          "%b %Y"
        )
      end

      def humanized_datetime(%DateTime{} = datetime) do
        Calendar.strftime(
          datetime,
          "%b %Y"
        )
      end

      @minute 60
      @hour @minute * 60
      @day @hour * 24
      @month @day * 30
      @year @month * 12

      # Check
      def relative_datetime(%DateTime{} = datetime) do
        DateTime.to_iso8601(datetime)
        |> relative_datetime()
      end

      def relative_datetime(datetime) do
        {:ok, datetime, _} = DateTime.from_iso8601(datetime)
        diff = DateTime.diff(DateTime.utc_now(), datetime)

        if diff do
          cond do
            diff <= 5 -> {nil, "now"}
            diff <= 60 -> {diff, "seconds ago"}
            diff <= @hour -> {div(diff, @minute), "minutes ago"}
            diff > @hour && diff <= @day -> {div(diff, @hour), "hours ago"}
            diff > @day && diff <= @month -> {div(diff, @day), "days ago"}
            diff > @month && diff <= @year -> {div(diff, @month), "months ago"}
            true -> {div(diff, @year), "years ago"}
          end
        end
      end

      def gravatar_url(email, size \\ 48)

      def gravatar_url(nil, size) do
        "https://www.gravatar.com/avatar/#{String.duplicate("0", 32)}?s=#{size}&d=mp"
      end

      def gravatar_url(email, size) do
        hash =
          :crypto.hash(:sha256, String.trim(email))
          |> Base.encode16(case: :lower)

        "https://www.gravatar.com/avatar/#{hash}?s=#{size}&d=retro"
      end
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: ToolboxWeb.Endpoint,
        router: ToolboxWeb.Router,
        statics: ToolboxWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/live_view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
