defmodule Ask.SurveySimulationController do
  use Ask.Web, :api_controller
  use Ask.Web, :append_assigns_to_action

  alias Ask.{Project, Survey, Questionnaire, RespondentGroup, Respondent, Channel}
  alias Ask.Runtime.Session

  plug :assign_project when action in [:initial_state, :status, :stop]
  plug :assign_project_for_change when action in [:simulate]
  plug :load_survey_simulation when action in [:initial_state, :status, :stop]

  plug :put_view, Ask.SurveyView

  def simulate(conn, %{
    "questionnaire_id" => questionnaire_id,
    "phone_number" => phone_number,
    "mode" => mode,
    "channel_id" => channel_id
  }, %{project: project}) do
    questionnaire = Repo.one!(from q in Questionnaire,
      where: q.project_id == ^project.id,
      where: q.id == ^questionnaire_id)

    channel = Repo.get!(Channel, channel_id)

    survey = %Survey{
      simulation: true,
      project_id: project.id,
      name: questionnaire.name,
      mode: [[mode]],
      state: "ready",
      cutoff: 1,
      schedule: Ask.Schedule.always()}
    |> Ecto.Changeset.change
    |> Repo.insert!

    respondent_group = %RespondentGroup{
      survey_id: survey.id,
      name: "default",
      sample: [phone_number],
      respondents_count: 1}
    |> Ecto.Changeset.change
    |> Repo.insert!

    %Ask.SurveyQuestionnaire{
      survey_id: survey.id,
      questionnaire_id: String.to_integer(questionnaire_id)}
    |> Ecto.Changeset.change
    |> Repo.insert!

    %Ask.RespondentGroupChannel{
      respondent_group_id: respondent_group.id,
      channel_id: channel.id,
      mode: mode}
    |> Ecto.Changeset.change
    |> Repo.insert!

    %Respondent{
      survey_id: survey.id,
      respondent_group_id: respondent_group.id,
      phone_number: phone_number,
      sanitized_phone_number: phone_number,
      canonical_phone_number: phone_number,
      hashed_number: phone_number}
    |> Ecto.Changeset.change
    |> Repo.insert!

    conn
    |> Ask.SurveyController.launch(%{"survey_id" => survey.id}, %{project: project})
  end

  def status(conn, _params, %{survey: survey}) do
    # The simulation has only one respondent
    respondent = Repo.one!(from r in Respondent,
      where: r.survey_id == ^survey.id)

    responses = respondent
    |> assoc(:responses)
    |> Repo.all
    |> Enum.map(fn response ->
      {response.field_name, response.value}
    end)
    |> Enum.into(%{})

    session = respondent.session
    session =
      if session do
        Session.load(session)
      else
        nil
      end

    {step_id, step_index} =
      if session do
        {
          Session.current_step_id(session),
          case Session.current_step_index(session) do
            {section_index, step_index} -> [section_index, step_index]
            index -> index
          end
        }
      else
        {nil, nil}
      end

    conn
    |> json(%{
      "data" => %{
        "state" => respondent.state,
        "disposition" => respondent.disposition,
        "step_id" => step_id,
        "step_index" => step_index,
        "responses" => responses,
      }
    })
  end

  def stop(conn, _params, %{project: project, survey: survey}) do
    questionnaire = survey
    |> assoc(:questionnaires)
    |> Repo.one!

    Repo.delete!(survey)
    Project.touch!(project)

    conn
    |> json(%{
      "data" => %{
        "questionnaire_id" => questionnaire.snapshot_of
      }
    })
  end

  def initial_state(conn, %{"mode" => mode}, %{survey: survey}) do
    render_initial_state(conn, survey.id, mode)
  end

  defp render_initial_state(conn, survey_id, "mobileweb" = _mode) do
    # The simulation has only one respondent
    respondent = Repo.one!(from r in Respondent,
    where: r.survey_id == ^survey_id)

    response = if (respondent.session) do
      session = Session.load_respondent_session(respondent, true)

      json(conn, %{
        "data" => %{
          "mobile_contact_messages" => Session.mobile_contact_message(session)
        }
      })
    else
      conn
      |> send_resp(:not_found, "")
    end

    response
  end

  defp render_initial_state(conn, _survey_id, _mode) do
    json(conn, %{"data" => %{}})
  end

  defp load_survey_simulation(conn, _) do
    %{project: project} = conn.assigns
    %{"survey_id" => survey_id} = conn.params

    survey = project
    |> assoc(:surveys)
    |> where([s], s.simulation)
    |> Repo.get!(survey_id)

    conn |> assign(:survey, survey)
  end
end
