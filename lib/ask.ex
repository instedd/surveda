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
      supervisor(Ask.Endpoint, []),
      supervisor(Ask.MetricsEndpoint, [])
      # Start your own worker by calling: Ask.Worker.start_link(arg1, arg2, arg3)
      # worker(Ask.Worker, [arg1, arg2, arg3]),
    ]

    children = if Mix.env != :test && !IEx.started? do
      [
        worker(Ask.OAuthTokenServer, []),
        worker(Ask.Runtime.SurveyLogger, []),
        worker(Ask.Runtime.Broker, []),
        worker(Ask.FloipPusher, []),
        worker(Ask.JsonSchema, []),
        worker(Ask.Runtime.ChannelStatusServer, []),
        worker(Ask.Config, [])
      | children]
    else
      children
    end

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ask.Supervisor]
    supervisor_result = Supervisor.start_link(children, opts)
    survey_canceller_children = if Mix.env != :test && !IEx.started? do
      [
        GenStage.start_link(Ask.RespondentsCancellerProducer, nil, name: RespondentsCancellerProducer),
        GenStage.start_link(Ask.RespondentsCancellerConsumer, 0, name: RespondentsCancellerConsumer_1),
        GenStage.start_link(Ask.RespondentsCancellerConsumer, 0, name: RespondentsCancellerConsumer_2),
        GenStage.start_link(Ask.RespondentsCancellerConsumer, 0, name: RespondentsCancellerConsumer_3)
      ]
    end

    if Mix.env != :test && !IEx.started? do
      Supervisor.start_link(survey_canceller_children, strategy: :rest_for_one)
    end
    supervisor_result
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Ask.Endpoint.config_change(changed, removed)
    :ok
  end
end
