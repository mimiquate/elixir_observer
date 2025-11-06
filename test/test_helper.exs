Mox.defmock(Toolbox.Auth.Github.OAuthTestHost, for: Toolbox.Auth.Github.Host)
Mox.defmock(Toolbox.Auth.Github.APITestHost, for: Toolbox.Auth.Github.Host)

defmodule Helpers do
  def test_server_github_oauth do
    {:ok, test_server} = TestServer.start()

    Mox.stub(Toolbox.Auth.Github.OAuthTestHost, :connect_url, fn ->
      TestServer.url(test_server)
    end)

    test_server
  end

  def test_server_github_api do
    {:ok, test_server} = TestServer.start()

    Mox.stub(Toolbox.Auth.Github.APITestHost, :connect_url, fn ->
      TestServer.url(test_server)
    end)

    test_server
  end
end

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Toolbox.Repo, :manual)
Application.put_env(:wallaby, :base_url, ToolboxWeb.Endpoint.url())
{:ok, _} = Application.ensure_all_started(:wallaby)
