defmodule Ask.MetricsEndpoint do
  use Phoenix.Endpoint, otp_app: :ask

  plug Ask.PrometheusExporter
end
