defmodule Toolbox.GithubTest do
  use ExUnit.Case, async: true

  alias Toolbox.Github

  describe "parse_link/1" do
    test "parses basic GitHub URL correctly" do
      result = Github.parse_link("https://github.com/org/repo")

      assert result == %{"owner" => "org", "repo" => "repo"}
    end

    test "parses GitHub URL with hyphen in repo name" do
      result = Github.parse_link("https://github.com/org/repo-name")

      assert result == %{"owner" => "org", "repo" => "repo-name"}
    end

    test "parses GitHub URL with underscore in repo name" do
      result = Github.parse_link("https://github.com/org/repo_name")

      assert result == %{"owner" => "org", "repo" => "repo_name"}
    end

    test "parses GitHub URL with hyphen, underscore and number in repo name" do
      result = Github.parse_link("https://github.com/org/repo-name_1")

      assert result == %{"owner" => "org", "repo" => "repo-name_1"}
    end

    test "does not parse GitHub URL with angle brackets" do
      result = Github.parse_link("https://github.com/<org>/<repo>")

      assert result == nil
    end

    test "parses GitHub URL with www prefix" do
      result = Github.parse_link("https://www.github.com/org/repo")

      assert result == %{"owner" => "org", "repo" => "repo"}
    end

    test "parses GitHub URL with http protocol" do
      result = Github.parse_link("http://github.com/org/repo")

      assert result == %{"owner" => "org", "repo" => "repo"}
    end
  end
end
