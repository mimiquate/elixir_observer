defmodule ElixirToolbox.Repo do
  use Ecto.Repo,
    otp_app: :elixir_toolbox,
    adapter: Ecto.Adapters.Postgres
end
