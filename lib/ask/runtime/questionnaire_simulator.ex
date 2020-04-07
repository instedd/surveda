defmodule Ask.QuestionnaireSimulation do
  defstruct [:respondent, :questionnaire, :survey, :session]
end

defmodule Ask.QuestionnaireSimulator do
  use Agent

  alias Ask.{Survey, Respondent, Questionnaire, Project, SystemTime}
  alias Ask.Runtime.{Survey, Session, Flow}

  def start_link() do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def add_respondent_simulation(respondent_id, simulation_status) do
    Agent.update(Ask.QuestionnaireSimulator, &Map.put(&1, respondent_id, simulation_status))
  end

  def get_respondent_status(respondent_id) do
    Agent.get(Ask.QuestionnaireSimulator, &Map.get(&1, respondent_id))
  end

  def start_simulation(%Project{} = project, %Questionnaire{} = questionnaire, mode) do

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
      questionnaire_id: questionnaire.id,
      mode: [mode],
      disposition: "queued"}

    session = Session.start(questionnaire, respondent, nil, mode, Ask.Schedule.always(), [], nil, nil, [], nil, false)
              |> Survey.handle_session_step(SystemTime.time.now, false)

    Ask.QuestionnaireSimulator.add_respondent_simulation(respondent.id, %Ask.QuestionnaireSimulation{survey: survey, questionnaire: questionnaire, respondent: respondent, session: session})
    session
  end

  def process_respondent_response(respondent_id, response) do
    simulation = Ask.QuestionnaireSimulator.get_respondent_status(respondent_id)
    respondent = simulation |> prepare_respondent
    reply = Flow.Message.reply(response)
    session = Survey.sync_step(respondent, reply, nil, SystemTime.time.now, false)
    Ask.QuestionnaireSimulator.add_respondent_simulation(respondent.id, %Ask.QuestionnaireSimulation{simulation | session:  session})
    session
  end

  defp prepare_respondent(simulation) do
    %Respondent{simulation.respondent | session: Session.dump(simulation.session)}
  end
end

