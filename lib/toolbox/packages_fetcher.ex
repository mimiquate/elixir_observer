defmodule Toolbox.PackagesFetcher do
  def child_spec(_arg) do
    Periodic.child_spec(
      id: __MODULE__,
      run: &run/0,
      every: :timer.hours(1),
      when: fn -> match?(%Time{hour: 5}, Time.utc_now()) end,
      on_overlap: :stop_previous
    )
  end

  defp run do
    Toolbox.Tasks.Hexpm.run()
    Toolbox.Tasks.Github.run()
  end
end
