defmodule Ask.QuestionnaireSimulation do
  defstruct [:respondent, :questionnaire, :session]
end

defmodule Ask.SimulatorChannel do
  defstruct patterns: []
end

defmodule Ask.QuestionnaireSimulator do
  use Agent

  alias Ask.{Survey, Respondent, Questionnaire, Project, SystemTime, Runtime}
  alias Ask.Runtime.{Session, Flow}

  def start_link() do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def add_respondent_simulation(respondent_id, simulation_status) do
    Agent.update(Ask.QuestionnaireSimulator, &Map.put(&1, respondent_id, simulation_status))
  end

  def get_respondent_status(respondent_id) do
    Agent.get(Ask.QuestionnaireSimulator, &Map.get(&1, respondent_id))
  end

  def start_simulation(%Project{} = project, %Questionnaire{} = questionnaire, mode \\ "sms_simulator") do
    survey = %Survey{
      simulation: true,
      project_id: project.id,
      name: questionnaire.name,
      mode: [[mode]],
      state: "running",
      cutoff: 1,
      schedule: Ask.Schedule.always(),
      started_at: Timex.now
    }

    respondent = %Respondent{
      id: Ecto.UUID.generate(),
      survey_id: survey.id,
      survey: survey,
      questionnaire_id: questionnaire.id,
      mode: [mode],
      disposition: "queued",
      phone_number: "",
      canonical_phone_number: "",
      sanitized_phone_number: ""
    }

    IO.inspect(respondent.id, label: "Starting session for respondent id")
    session = Session.start(questionnaire, respondent, %Ask.SimulatorChannel{}, mode, Ask.Schedule.always(), [], nil, nil, [], nil, false, false)
              |> Runtime.Survey.handle_session_step(SystemTime.time.now, false)

    Ask.QuestionnaireSimulator.add_respondent_simulation(respondent.id, %Ask.QuestionnaireSimulation{questionnaire: questionnaire, respondent: respondent, session: session})
    session
  end

  def process_respondent_response(respondent_id, response) do
    simulation = Ask.QuestionnaireSimulator.get_respondent_status(respondent_id)
    respondent = simulation |> prepare_respondent
    reply = Flow.Message.reply(response)
    session = Runtime.Survey.sync_step(respondent, reply, nil, SystemTime.time.now, false)
    Ask.QuestionnaireSimulator.add_respondent_simulation(respondent.id, %Ask.QuestionnaireSimulation{simulation | session:  session})
    session
  end

  defp prepare_respondent(simulation) do
    %Respondent{simulation.respondent | session: Session.dump(simulation.session)}
  end
end

