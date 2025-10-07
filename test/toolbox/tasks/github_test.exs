defmodule Toolbox.Tasks.GitHubTest do
  use Toolbox.DataCase, async: true

  alias Toolbox.Packages
  alias Toolbox.Tasks.GitHub
  alias Toolbox.GithubSnapshot.Activity
  alias Toolbox.GithubSnapshot.PullRequest

  describe "run/2" do
    test "creates github snapshot with successful response" do
      {:ok, package} = Packages.create_package(%{name: "test_package"})
      github_link = "https://github.com/owner/test_package"

      Packages.create_hexpm_snapshot(%{
        package_id: package.id,
        data: %{}
      })

      TestServer.add("/repos/owner/test_package",
        to: fn conn ->
          conn
          |> Plug.Conn.put_resp_header("content-type", "application/json")
          |> Plug.Conn.send_resp(200, ~s({"id": 123}))
        end
      )

      TestServer.add("/graphql",
        via: :post,
        to: fn conn ->
          conn
          |> Plug.Conn.put_resp_header("content-type", "application/json")
          |> Plug.Conn.send_resp(200, ~s({
            "data": {
              "openIssueCount": {"issueCount": 1},
              "closedIssueCount": {"issueCount": 45},
              "openPRCount": {"issueCount": 0},
              "mergedPRCount": {"issueCount": 75},
              "repository": {
                "pullRequests": {
                  "nodes": [
                    {
                      "createdAt": "2025-05-23T16:57:23Z",
                      "mergedAt": "2025-05-25T16:58:30Z",
                      "permalink": "https://github.com/mtrudel/bandit/pull/495",
                      "mergedBy": {
                        "login": "mtrudel",
                        "avatarUrl": "https://avatars.githubusercontent.com/"
                      },
                      "title": "Streamline keepalive logic"
                    }
                  ]
                },
                "latestTag": {
                  "nodes": [
                    {
                        "name": "1.7.0",
                        "compare": {
                            "aheadBy": 5
                        }
                    }
                  ]
                },
                "changelog": null
              }
            }
          }
          ))
        end
      )

      Application.put_env(:toolbox, :github_base_url, TestServer.url())

      GitHub.run(package, github_link)

      snapshot = Packages.get_package_by_name(package.name).latest_github_snapshot

      assert snapshot.data == %{
               "id" => 123,
               "has_changelog" => false
             }

      assert snapshot.activity == %Activity{
               closed_issue_count: 45,
               merged_pr_count: 75,
               open_issue_count: 1,
               open_pr_count: 0,
               last_tag: "1.7.0",
               last_tag_behind_by: 5,
               pull_requests: [
                 %PullRequest{
                   permalink: "https://github.com/mtrudel/bandit/pull/495",
                   created_at: ~U[2025-05-23 16:57:23Z],
                   title: "Streamline keepalive logic",
                   merged_at: ~U[2025-05-25 16:58:30Z],
                   merged_by_login: "mtrudel",
                   merged_by_avatar_url: "https://avatars.githubusercontent.com/"
                 }
               ]
             }
    end

    test "delete old snapshot when not found GitHub", %{} do
      {:ok, package} = Packages.create_package(%{name: "test_package"})
      github_link = "https://github.com/owner/non_existent_repo"

      Packages.create_hexpm_snapshot(%{
        package_id: package.id,
        data: %{}
      })

      Packages.upsert_github_snapshot(%{
        package_id: package.id,
        data: %{}
      })

      TestServer.add("/repos/owner/non_existent_repo",
        to: fn conn ->
          Plug.Conn.send_resp(conn, 404, "")
        end
      )

      Application.put_env(:toolbox, :github_base_url, TestServer.url())

      GitHub.run(package, github_link)

      refute Packages.get_package_by_name(package.name).latest_github_snapshot
    end
  end
end
