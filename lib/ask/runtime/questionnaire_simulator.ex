defmodule Ask.QuestionnaireSimulation do
  defstruct [:respondent, :questionnaire, :survey]
end

defmodule Ask.QuestionnaireSimulator do
  use Agent

  alias Ask.{Survey, Respondent, Questionnaire, Project}

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
      survey_id: survey.id
    }

    Ask.QuestionnaireSimulator.add_respondent_simulation(respondent.id, %Ask.QuestionnaireSimulation{survey: survey, questionnaire: questionnaire, respondent: respondent})
  end
end

