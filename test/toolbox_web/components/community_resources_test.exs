defmodule ToolboxWeb.Components.CommunityResourcesTest do
  use ToolboxWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ToolboxWeb.Components.CommunityResources

  alias Toolbox.Package.CommunityResource

  describe "community_resource/1" do
    test "renders community section with resources data" do
      resources = [
        %CommunityResource{
          type: :video,
          title: "Resource 1",
          description: "Description 1",
          url: "http://example.com/1"
        },
        %CommunityResource{
          type: :article,
          title: "Resource 2",
          description: "Description 2",
          url: "http://example.com/2"
        }
      ]

      html = render_component(&community_resources/1, resources: resources)
      doc = LazyHTML.from_document(html)

      assert 1 ==
               doc
               |> LazyHTML.query(data_test_attr(:resource_list))
               |> node_count()

      assert 2 ==
               doc
               |> LazyHTML.query(data_test_attr(:resource_item))
               |> node_count()

      title_texts =
        doc
        |> LazyHTML.query(data_test_attr(:resource_title))
        |> Enum.map(&String.trim(LazyHTML.text(&1)))

      assert "Resource 1" in title_texts
      assert "Resource 2" in title_texts

      description_texts =
        doc
        |> LazyHTML.query(data_test_attr(:resource_description))
        |> Enum.map(&String.trim(LazyHTML.text(&1)))

      assert "Description 1" in description_texts
      assert "Description 2" in description_texts

      url_texts =
        doc
        |> LazyHTML.query(data_test_attr(:resource_url))
        |> LazyHTML.attribute("href")

      assert "http://example.com/1" in url_texts
      assert "http://example.com/2" in url_texts
    end
  end
end
