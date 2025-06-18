defmodule Toolbox.OtelSampler do
  require OpenTelemetry.Tracer, as: Tracer

  @behaviour :otel_sampler

  @impl :otel_sampler
  def setup(_) do
    %{}
  end

  @impl :otel_sampler
  def description(_) do
    "Sampler"
  end

  @impl :otel_sampler
  def should_sample(
        _ctx,
        _trace_id,
        _links,
        _span_name,
        _span_kind,
        %{source: "oban_jobs"},
        _config_attributes
      ) do
    {:drop, [], []}
  end

  @impl :otel_sampler
  def should_sample(
        _ctx,
        _trace_id,
        _links,
        _span_name,
        _span_kind,
        %{"db.statement": s},
        _config_attributes
      )
      when s in ["begin", "commit"] do
    {:drop, [], []}
  end

  @impl :otel_sampler
  def should_sample(
        ctx,
        _trace_id,
        _links,
        _span_name,
        _span_kind,
        _attributes,
        _config_attributes
      ) do
    tracestate = Tracer.current_span_ctx(ctx) |> OpenTelemetry.Span.tracestate()
    {:record_and_sample, [], tracestate}
  end
end
