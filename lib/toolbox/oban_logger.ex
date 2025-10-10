defmodule Toolbox.ObanLogger do
  require Logger

  def handle_event([:oban, :job, :exception], _measure, meta, _) do
    Logger.error("[Oban] #{inspect(meta.error)}")
  end
end
