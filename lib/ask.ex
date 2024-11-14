defmodule Ask do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    Ask.PhoenixInstrumenter.setup()
    Ask.PrometheusExporter.setup()
    Ask.SurvedaMetrics.setup()

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Ask.Repo, []),
      # Start the endpoint when the application starts
      supervisor(AskWeb.Endpoint, []),
      supervisor(Ask.MetricsEndpoint, []),
      supervisor(Registry, [:unique, :channel_broker_registry]),
      worker(Ask.Runtime.ChannelBrokerAgent, []),
      supervisor(Ask.Runtime.ChannelBrokerSupervisor, []),
      {Mutex, name: Ask.Mutex}
      # Start your own worker by calling: Ask.Worker.start_link(arg1, arg2, arg3)
      # worker(Ask.Worker, [arg1, arg2, arg3]),
    ]

    children =
      cond do
        Mix.env() == :test ->
          [
            worker(Ask.DatabaseCleaner, [])
            | children
          ]

        !IEx.started?() ->
          [
            worker(Ask.OAuthTokenServer, []),
            worker(Ask.Runtime.SurveyLogger, []),
            worker(Ask.Runtime.SurveyBroker, []),
            worker(Ask.FloipPusher, []),
            worker(Ask.JsonSchema, []),
            worker(Ask.Runtime.ChannelStatusServer, []),
            worker(Ask.Config, []),
            worker(Ask.Runtime.QuestionnaireSimulatorStore, []),
            worker(Ask.SurveyResults, [])
            | children
          ] ++ [
              # SurveyCancellerSupervisor depends on Ask.Repo, so must be started (and declared!) after it
              supervisor(Ask.Runtime.SurveyCancellerSupervisor, [])
            ]

        true ->
          children
      end

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ask.Supervisor]
    {:ok, _} = Logger.add_backend(Sentry.LoggerBackend)

    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    AskWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
