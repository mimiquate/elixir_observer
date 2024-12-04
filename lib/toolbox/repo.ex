defmodule Toolbox.Repo do
  use Ecto.Repo,
    otp_app: :toolbox,
    adapter: Ecto.Adapters.Postgres
end
