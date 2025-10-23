defmodule Toolbox.Cache do
  use Nebulex.Cache,
    otp_app: :toolbox,
    adapter: Application.compile_env!(:toolbox, [__MODULE__, :adapter])
end
