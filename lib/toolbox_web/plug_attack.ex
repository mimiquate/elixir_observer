defmodule ToolboxWeb.PlugAttack do
  use PlugAttack

  @storage {PlugAttack.Storage.Ets, ToolboxWeb.PlugAttack.Storage}

  rule "allow local", conn do
    allow(conn.remote_ip == {127, 0, 0, 1})
  end

  rule "throttle by ip", conn do
    throttle(conn.remote_ip,
      period: 60_000,
      limit: 100,
      storage: @storage
    )
  end
end
