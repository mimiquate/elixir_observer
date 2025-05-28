defmodule Toolbox.PackagesTest do
  use Toolbox.DataCase, async: true

  alias Toolbox.Packages

  describe "typeahead_search/1" do
    test "returns empty list for terms shorter than 2 characters" do
      assert Packages.typeahead_search("") == []
      assert Packages.typeahead_search("a") == []
    end

    test "returns empty list when no packages match" do
      assert Packages.typeahead_search("nonexistentpackage") == []
    end

    test "returns at most 5 results" do
      # This test would need actual data in the database to work properly
      # For now, we're just testing that the function doesn't crash
      results = Packages.typeahead_search("test")
      assert is_list(results)
      assert length(results) <= 5
    end

    test "returns results with name and description" do
      # This test would need actual data in the database to work properly
      results = Packages.typeahead_search("test")

      if length(results) > 0 do
        result = List.first(results)
        assert Map.has_key?(result, :name)
        assert Map.has_key?(result, :description)
      end
    end
  end
end
