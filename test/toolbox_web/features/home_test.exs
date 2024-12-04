defmodule ToolboxWeb.Features.HomeTest do
  use ExUnit.Case, async: true
  use Wallaby.Feature

  feature "home page", %{session: session} do
    session
    |> visit("/")
    |> assert_text("Elixir Toolbox")
  end
end
