defmodule ToolboxWeb.Features.SearchNavigationTest do
  use ExUnit.Case, async: false
  use Wallaby.Feature

  import ExUnit.CaptureLog

  feature "going back with the home search focused does not crash the LiveView", %{
    session: session
  } do
    error_log =
      capture_log([level: :error], fn ->
        session
        |> visit("/")
        |> click(Query.link("Categories"))
        |> assert_has(Query.css("[data-test-category-item]", minimum: 1))
        |> click(Query.css("nav a[href='/']"))
        |> assert_has(Query.text("Find, compare, and explore Elixir packages"))
        |> click(Query.text_field("Find packages"))

        # Wait longer than the input's phx-debounce (300ms), or the bug is not triggered
        Process.sleep(500)

        session
        |> execute_script("window.history.back()")
        |> assert_has(Query.css("[data-test-category-item]", minimum: 1))
      end)

    refute error_log =~ ~s(UserMenu.handle_event("handle_blur")
  end
end
