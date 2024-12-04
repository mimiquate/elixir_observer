ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Toolbox.Repo, :manual)
Application.put_env(:wallaby, :base_url, ToolboxWeb.Endpoint.url())
{:ok, _} = Application.ensure_all_started(:wallaby)
