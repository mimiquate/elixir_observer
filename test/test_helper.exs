defmodule Helpers do
  def test_server_github_oauth do
    {:ok, test_server} = TestServer.start()

    Process.put({Toolbox.Github, :oauth_host_url}, TestServer.url(test_server))

    test_server
  end

  def test_server_github_api do
    {:ok, test_server} = TestServer.start()

    Process.put({Toolbox.Github, :api_host_url}, TestServer.url(test_server))

    test_server
  end
end

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Toolbox.Repo, :manual)
Application.put_env(:wallaby, :base_url, ToolboxWeb.Endpoint.url())
{:ok, _} = Application.ensure_all_started(:wallaby)
