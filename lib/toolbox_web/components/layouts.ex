defmodule ToolboxWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use ToolboxWeb, :controller` and
  `use ToolboxWeb, :live_view`.
  """
  use ToolboxWeb, :html

  embed_templates "layouts/*"

  def website_json_ld do
    base_url = url(~p"/")

    %{
      "@context" => "https://schema.org",
      "@type" => "WebSite",
      "name" => "Elixir Observer",
      "url" => base_url,
      "description" =>
        "Find, compare, and explore Elixir packages for your next project. " <>
          "Search 2000+ packages with GitHub activity insights.",
      "potentialAction" => %{
        "@type" => "SearchAction",
        "target" => %{
          "@type" => "EntryPoint",
          "urlTemplate" => "#{base_url}searches/{search_term_string}"
        },
        "query-input" => "required name=search_term_string"
      },
      "publisher" => %{
        "@type" => "Organization",
        "name" => "Mimiquate",
        "url" => "https://mimiquate.com"
      }
    }
    |> Jason.encode!()
  end

  def og_title(%{package: %{name: name}}) do
    name
  end

  def og_title(_) do
    "Elixir Observer"
  end

  def og_description(%{package: %{description: description}}) do
    description
  end

  def og_description(_) do
    "Find, compare, and explore Elixir packages for your next project."
  end

  def robots(%{conn: %{private: %{seo: true}}}) do
    "all"
  end

  def robots(_assigns) do
    "none"
  end
end
