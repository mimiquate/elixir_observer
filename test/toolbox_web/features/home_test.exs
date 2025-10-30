defmodule ToolboxWeb.Features.HomeTest do
  use ExUnit.Case, async: true
  use Wallaby.Feature

  feature "home page", %{session: session} do
    session
    |> visit("/")
    |> fill_in(Query.text_field("Find packages"), with: "bandit")
  end
end
