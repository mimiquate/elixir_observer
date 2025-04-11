defmodule Toolbox.PackagesFetcher do
  def child_spec(_arg) do
    Periodic.child_spec(
      id: __MODULE__,
      run: &run/0,
      every: :timer.hours(1),
      when: fn ->
        now = DateTime.utc_now()
        Date.day_of_week(now) == 7 && match?(%DateTime{hour: 5}, now)
      end,
      on_overlap: :stop_previous
    )
  end

  defp run do
    Toolbox.Tasks.Hexpm.run()
    Toolbox.Tasks.SCM.run()
  end
end
