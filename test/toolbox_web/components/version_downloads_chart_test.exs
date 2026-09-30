defmodule ToolboxWeb.Components.VersionDownloadsChartTest do
  use ToolboxWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ToolboxWeb.Components.VersionDownloadsChart

  defp version_downloads(versions) do
    Enum.map(versions, fn {version, downloads} ->
      %{version: version, downloads: downloads}
    end)
  end

  defp render_chart(version_downloads, recent_downloads, opts \\ []) do
    render_component(&version_downloads_chart/1,
      version_downloads: version_downloads,
      recent_downloads: recent_downloads,
      state: Keyword.get(opts, :state, :idle),
      has_more?: Keyword.get(opts, :has_more?, false)
    )
    |> LazyHTML.from_document()
  end

  describe "version_downloads_chart/1" do
    test "renders a loading spinner when version_downloads is nil (job still running)" do
      doc = render_chart(nil, 0, state: :loading)

      assert node_count(LazyHTML.query(doc, data_test_attr(:version_downloads_loading))) == 1
      assert node_count(LazyHTML.query(doc, data_test_attr(:version_downloads_list))) == 0
    end

    test "renders a failure state with a retry action when the job appears stuck" do
      doc = render_chart(nil, 0, state: :failed)

      assert node_count(LazyHTML.query(doc, data_test_attr(:version_downloads_failed))) == 1
      assert node_count(LazyHTML.query(doc, data_test_attr(:version_downloads_loading))) == 0

      retry = LazyHTML.query(doc, "[phx-click='expand_version_downloads']")
      assert node_count(retry) == 1
    end

    test "renders the empty state when there is no version data" do
      doc = render_chart(version_downloads([]), 0)

      assert node_count(LazyHTML.query(doc, data_test_attr(:version_downloads_empty))) == 1
    end

    test "keeps every revealed version as its own row, however small its share" do
      doc =
        [{"1.0.0", 600}, {"2.0.0", 350}, {"3.0.0", 15}, {"4.0.0", 1}]
        |> version_downloads()
        |> render_chart(966)

      assert node_count(LazyHTML.query(doc, data_test_attr(:version_downloads_row))) == 4
    end

    test "never shows a negative Others when fetched downloads exceed the package total" do
      doc =
        [{"2.0.0", 100}, {"1.0.0", 50}]
        |> version_downloads()
        |> render_chart(100)

      assert node_count(LazyHTML.query(doc, data_test_attr(:version_downloads_row, "Others"))) ==
               0

      assert node_count(LazyHTML.query(doc, data_test_attr(:version_downloads_row))) == 2
    end

    test "shows a 'Show more' button when there are more versions included in Others" do
      doc =
        [{"1.0.0", 500}]
        |> version_downloads()
        |> render_chart(1000, has_more?: true)

      assert node_count(LazyHTML.query(doc, data_test_attr(:version_downloads_show_more))) == 1
    end

    test "does not show 'Show more' when there is no remaining Others share" do
      doc =
        [{"1.0.0", 1_000}]
        |> version_downloads()
        |> render_chart(1000, has_more?: true)

      assert node_count(LazyHTML.query(doc, data_test_attr(:version_downloads_show_more))) == 0
    end

    test "does not show a 'Show more' button once everything has been revealed" do
      doc =
        [{"1.0.0", 1000}]
        |> version_downloads()
        |> render_chart(1000, has_more?: false)

      assert node_count(LazyHTML.query(doc, data_test_attr(:version_downloads_show_more))) == 0
    end

    test "shows an inline spinner while a further page is loading" do
      doc =
        [{"1.0.0", 500}]
        |> version_downloads()
        |> render_chart(1000, has_more?: true, state: :loading)

      assert node_count(LazyHTML.query(doc, data_test_attr(:version_downloads_loading_more))) == 1
      assert node_count(LazyHTML.query(doc, data_test_attr(:version_downloads_show_more))) == 0
    end

    test "shows an inline retry when a further page failed, not the spinner or the button" do
      doc =
        [{"1.0.0", 500}]
        |> version_downloads()
        |> render_chart(1000, has_more?: true, state: :failed)

      assert node_count(LazyHTML.query(doc, data_test_attr(:version_downloads_more_failed))) == 1
      assert node_count(LazyHTML.query(doc, data_test_attr(:version_downloads_loading_more))) == 0
      assert node_count(LazyHTML.query(doc, data_test_attr(:version_downloads_show_more))) == 0

      retry = LazyHTML.query(doc, "[phx-click='show_more_version_downloads']")
      assert node_count(retry) == 1
    end
  end
end
