defmodule Toolbox.GithubSnapshot.PullRequestTest do
  use Toolbox.DataCase

  alias Toolbox.GithubSnapshot.PullRequest

  describe "changeset/2" do
    test "merged_by_login and merged_by_avatar_url can be blank" do
      attrs = %{
        permalink: "https://github.com/owner/repo/pull/1",
        created_at: ~U[2026-05-23 16:57:23Z],
        title: "Streamline keepalive logic",
        merged_at: ~U[2026-05-25 16:58:30Z],
        merged_by_login: nil,
        merged_by_avatar_url: nil
      }

      changeset = PullRequest.changeset(%PullRequest{}, attrs)

      assert changeset.valid?
    end
  end
end
