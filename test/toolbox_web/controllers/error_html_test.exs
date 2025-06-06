defmodule ToolboxWeb.ErrorHTMLTest do
  use ToolboxWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template

  test "renders 404.html" do
    assert render_to_string(ToolboxWeb.ErrorHTML, "404", "html", []) =~
             "Sorry, we couldn't find what you were looking for"
  end

  test "renders 500.html" do
    assert render_to_string(ToolboxWeb.ErrorHTML, "500", "html", []) =~
             "Sorry, something went wrong"
  end
end
