defmodule ToolboxWeb.Features.HomeTest do
  use ExUnit.Case, async: true
  use Wallaby.Feature

  feature "home page", %{session: session} do
    # https://github.com/elixir-wallaby/wallaby/issues/331#issuecomment-1873618554
    %URI{scheme: scheme, host: host, port: port} = ToolboxWeb.Endpoint.struct_url()

    session
    |> visit("#{scheme}://admin:secret@#{host}:#{port}/")
    |> assert_text("Elixir Toolbox")
  end
end
