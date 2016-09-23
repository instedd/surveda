defmodule Ask.RespondentControllerTest do
  use Ask.ConnCase
  alias Ask.Respondent

  @valid_attrs %{phone_number: "some content"}
  @invalid_attrs %{}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all entries on index", %{conn: conn} do
    project = insert(:project)
    survey = insert(:survey, project: project)
    conn = get conn, project_survey_respondent_path(conn, :index, project.id, survey.id)
    assert json_response(conn, 200)["data"] == []
  end

  test "fetches responses on index", %{conn: conn} do
    project = insert(:project)
    survey = insert(:survey, project: project)
    respondent = insert(:respondent, survey: survey)
    response = insert(:response, respondent: respondent, value: "Yes")
    conn = get conn, project_survey_respondent_path(conn, :index, project.id, survey.id)
    assert json_response(conn, 200)["data"] == [%{
      "id" => respondent.id,
      "phone_number" => respondent.phone_number,
      "survey_id" => survey.id,
      "date" => Ecto.DateTime.to_iso8601(response.updated_at),
      "responses" => [
        %{
          "value" => response.value,
          "name" => response.field_name
        }
      ]
    }]
  end

  test "lists stats for a given survey", %{conn: conn} do
    project = insert(:project)
    survey = insert(:survey, project: project)
    file = %Plug.Upload{path: "test/fixtures/respondent_phone_numbers.csv", filename: "phone_numbers.csv"}
    conn = post conn, project_survey_respondent_path(conn, :create, project.id, survey.id), file: file

    conn = get conn, project_survey_respondents_stats_path(conn, :stats, project.id, survey.id)
    assert json_response(conn, 200)["data"] == %{
      "pending" => 14,
      "completed" => 0,
      "active" => 0,
      "failed" => 0
    }
  end

  test "uploads CSV file with phone numbers and creates and renders resource when data is valid", %{conn: conn} do
    project = insert(:project)
    survey = insert(:survey, project: project)

    file = %Plug.Upload{path: "test/fixtures/respondent_phone_numbers.csv", filename: "phone_numbers.csv"}

    conn = post conn, project_survey_respondent_path(conn, :create, project.id, survey.id), file: file
    assert length(json_response(conn, 201)["data"]) == 14

    all = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)
    assert length(all) == 14
    assert Enum.at(all, 0).survey_id == survey.id
    assert Enum.at(all, 0).phone_number == "(549) 11 4234 2343"
  end

  test "updates survey state if the respondents CSV upload is the only remaining step on the survey wizard", %{conn: conn} do
    project = insert(:project)
    questionnaire = insert(:questionnaire, name: "test", project: project)
    survey = insert(:survey, project: project, cutoff: 4, questionnaire_id: questionnaire.id)
    channel = insert(:channel, name: "test")

    add_channel_to(survey, channel)

    assert survey.state == "not_ready"

    file = %Plug.Upload{path: "test/fixtures/respondent_phone_numbers.csv", filename: "phone_numbers.csv"}

    post conn, project_survey_respondent_path(conn, :create, project.id, survey.id), file: file

    new_survey = Repo.get(Ask.Survey, survey.id)

    assert new_survey.state == "ready"
  end

  test "deletes all the respondents from a survey", %{conn: conn} do
    project = insert(:project)
    survey = insert(:survey, project: project)
    {:ok, local_time } = Ecto.DateTime.cast :calendar.local_time()

    entries = File.stream!("test/fixtures/respondent_phone_numbers.csv") |>
    CSV.decode(separator: ?\t) |>
    Enum.map(fn row ->
      %{phone_number: Enum.at(row, 0), survey_id: survey.id, inserted_at: local_time, updated_at: local_time}
    end)

    {respondents_count, _ } = Repo.insert_all(Respondent, entries)

    all = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)
    assert length(all) == respondents_count

    conn = delete conn, project_survey_respondent_path(conn, :delete, survey.project.id, survey.id, -1)
    assert response(conn, 204)

    all = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)
    assert length(all) == 0
  end

  def add_channel_to(survey, channel) do
    channels_changeset = Repo.get!(Ask.Channel, channel.id) |> change

    changeset = survey
    |> Repo.preload([:channels])
    |> Ecto.Changeset.change
    |> put_assoc(:channels, [channels_changeset])

    Repo.update(changeset)
  end
end
