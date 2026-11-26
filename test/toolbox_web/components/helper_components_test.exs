defmodule ToolboxWeb.HelperComponentsTest do
  use ToolboxWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ToolboxWeb.HelperComponents

  describe "user_link/1" do
    test "renders the username when no inner block is given" do
      html = render_component(&user_link/1, username: "josevalim")
      doc = LazyHTML.from_document(html)

      link = LazyHTML.query(doc, "a")

      assert LazyHTML.attribute(link, "href") == ["https://hex.pm/users/josevalim"]
      assert LazyHTML.text(link) |> String.trim() == "josevalim"
    end
  end
end
