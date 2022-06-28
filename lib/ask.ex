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
      supervisor(Ask.Runtime.ChannelBrokerSupervisor, []),
      {Mutex, name: Ask.Mutex}
      # Start your own worker by calling: Ask.Worker.start_link(arg1, arg2, arg3)
      # worker(Ask.Worker, [arg1, arg2, arg3]),
    ]

    children =
      if Mix.env() != :test && !IEx.started?() do
        [
          worker(Ask.OAuthTokenServer, []),
          worker(Ask.Runtime.SurveyLogger, []),
          worker(Ask.Runtime.SurveyBroker, []),
          worker(Ask.FloipPusher, []),
          worker(Ask.JsonSchema, []),
          worker(Ask.Runtime.ChannelStatusServer, []),
          worker(Ask.Config, []),
          worker(Ask.Runtime.QuestionnaireSimulatorStore, [])
          | children
        ]
      else
        children
      end

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ask.Supervisor]
    {:ok, _} = Logger.add_backend(Sentry.LoggerBackend)

    supervisor_result = Supervisor.start_link(children, opts)

    # survey_canceller_children =
    #   if Mix.env() != :test && !IEx.started?() do
    #     # Start cancelling with survey_id = nil to check all surveys that must be cancelled
    #     survey_canceller = Ask.SurveyCanceller.start_cancelling(nil)

    #     case survey_canceller do
    #       :ignore ->
    #         nil

    #       %Ask.SurveyCanceller{processes: _, consumers_pids: _} ->
    #         survey_canceller.processes
    #     end
    #   end

    # if Mix.env() != :test && !IEx.started?() && survey_canceller_children do
    #   Supervisor.start_link(survey_canceller_children, strategy: :rest_for_one)
    # end

    supervisor_result
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    AskWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
