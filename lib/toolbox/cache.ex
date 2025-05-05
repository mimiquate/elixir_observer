defmodule Toolbox.Cache do
  use Nebulex.Cache,
    otp_app: :toolbox,
    adapter: Nebulex.Adapters.Local
end
