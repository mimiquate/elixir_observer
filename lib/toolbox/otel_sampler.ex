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

  @drop_statements [
    "begin",
    "commit",
    ~s|SELECT f1."value", f0."value", "public".oban_count_estimate(f1."value", f0."value") FROM json_array_elements_text($1) AS f0 CROSS JOIN json_array_elements_text($2) AS f1|,
    ~s|DELETE FROM "public"."oban_peers" AS o0 WHERE (o0."name" = $1) AND (o0."expires_at" < $2)|,
    ~s|INSERT INTO "public"."oban_peers" AS o0 ("name","node","started_at","expires_at") VALUES ($1,$2,$3,$4) ON CONFLICT ("name") DO UPDATE SET "expires_at" = $5|
  ]

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
      when s in @drop_statements do
    {:drop, [], []}
  end

  @impl :otel_sampler
  def should_sample(
        _ctx,
        _trace_id,
        _links,
        _span_name,
        _span_kind,
        %{"url.path": p},
        _config_attributes
      )
      when p in ["/live/longpoll", "/live/websocket"] do
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
