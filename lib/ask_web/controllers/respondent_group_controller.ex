defmodule AskWeb.RespondentGroupController do
  use AskWeb, :api_controller
  alias Ask.{Project, Survey, Respondent, RespondentGroup, Logger}
  alias Ask.Runtime.RespondentGroupAction

  plug :find_and_check_survey_state when action in [:create, :import_unused, :update, :delete, :replace]

  def index(conn, %{"project_id" => project_id, "survey_id" => survey_id}) do
    project =
      conn
      |> load_project(project_id)

    respondent_groups =
      project
      |> assoc(:surveys)
      |> Repo.get!(survey_id)
      |> assoc(:respondent_groups)
      |> preload(respondent_group_channels: :channel)
      |> Repo.all()

    render(conn, "index.json", respondent_groups: respondent_groups)
  end

  def create(conn, %{"file" => file}) do
    project = conn.assigns.loaded_project
    survey = conn.assigns.loaded_survey

    entries = entries_from_csv(file)

    if entries do
      case RespondentGroupAction.load_entries(entries, survey) do
        {:ok, loaded_entries} ->
          RespondentGroupAction.disable_incentive_if_respondent_id!(entries, survey)
          respondent_group = RespondentGroupAction.create(file.filename, loaded_entries, survey)
          project |> Project.touch!()

          conn
          |> put_status(:created)
          |> render("show.json", respondent_group: respondent_group)

        {:error, invalid_entries} ->
          render_invalid(conn, file.filename, invalid_entries)
      end
    else
      Logger.warn("Error when creating respondent group for survey: #{inspect(survey)}")
      render_unprocessable_entity(conn)
    end
  end

  def import_unused(conn, %{"source_survey_id" => source_survey_id}) do
    project = conn.assigns.loaded_project
    survey = conn.assigns.loaded_survey

    source_survey =
      project
      |> assoc(:surveys)
      |> Repo.get!(source_survey_id)

    if !Survey.terminated?(source_survey) do
      render_invalid_import(conn, source_survey.id, "NOT_TERMINATED", %{survey_state: source_survey.state})
    else
      entries = unused_respondents_from_survey(source_survey)

      if !Enum.empty?(entries) do
        sample_name = "__imported_from_survey_#{source_survey.id}.csv"
        case RespondentGroupAction.load_entries(entries, survey) do
          {:ok, loaded_entries} ->
            survey |> RespondentGroupAction.disable_incentives_if_disabled_in_source!(source_survey)
            respondent_group = RespondentGroupAction.create(sample_name, loaded_entries, survey)
            project |> Project.touch!()

            conn
            |> put_status(:created)
            |> render("show.json", respondent_group: respondent_group)

          {:error, invalid_entries} ->
            # I don't see how numbers that were valid in a terminated survey would now be invalid when
            # importing them into another survey, but we'll handle that just in case - and `loaded_entries`
            # requires that, anyways
            render_invalid_import(conn, source_survey.id, "INVALID_ENTRIES", %{invalid_entries: invalid_entries})
        end
      else
        render_invalid_import(conn, source_survey.id, "NO_SAMPLE")
      end
    end
  end

  def update(conn, %{"id" => id, "respondent_group" => respondent_group_params}) do
    survey = conn.assigns.loaded_survey

    respondent_group =
      survey
      |> assoc(:respondent_groups)
      |> Repo.get!(id)
      |> RespondentGroup.changeset(respondent_group_params)
      |> Repo.update!()

    update_channels(id, respondent_group_params)

    respondent_group =
      respondent_group
      |> Repo.preload(:respondent_group_channels)

    survey
    |> Repo.preload([:questionnaires])
    |> Repo.preload([:quota_buckets])
    |> Repo.preload(respondent_groups: [respondent_group_channels: :channel])
    |> change
    |> Survey.update_state()
    |> Repo.update!()

    conn
    |> render("show.json", respondent_group: respondent_group)
  end

  def add(conn, %{
        "project_id" => project_id,
        "survey_id" => survey_id,
        "respondent_group_id" => id,
        "file" => file
      }) do
    project =
      conn
      |> load_project_for_change(project_id)

    survey =
      project
      |> assoc(:surveys)
      |> Repo.get!(survey_id)

    respondent_group =
      survey
      |> assoc(:respondent_groups)
      |> Repo.get!(id)
      |> Repo.preload(:respondent_group_channels)

    project |> Project.touch!()

    case survey.locked do
      false ->
        entries = entries_from_csv(file)

        if entries do
          case RespondentGroupAction.load_entries(entries, survey) do
            {:ok, loaded_entries} ->
              RespondentGroupAction.disable_incentive_if_respondent_id!(entries, survey)

              respondent_group =
                RespondentGroupAction.add_respondents(
                  respondent_group,
                  loaded_entries,
                  file.filename,
                  conn
                )

              render(conn, "show.json", respondent_group: respondent_group)

            {:error, invalid_entries} ->
              render_invalid(conn, file.filename, invalid_entries)
          end
        else
          Logger.warn("Error when creating respondent group for survey: #{inspect(survey)}")
          render_unprocessable_entity(conn)
        end

      true ->
        conn
        |> put_status(:unprocessable_entity)
        |> render("show.json", respondent_group: respondent_group)
    end
  end

  def replace(conn, %{"respondent_group_id" => id, "file" => file}) do
    project = conn.assigns.loaded_project
    survey = conn.assigns.loaded_survey

    respondent_group =
      survey
      |> assoc(:respondent_groups)
      |> Repo.get!(id)

    entries = entries_from_csv(file)

    if entries do
      case RespondentGroupAction.load_entries(entries, survey) do
        {:ok, loaded_entries} ->
          RespondentGroupAction.disable_incentive_if_respondent_id!(entries, survey)

          respondent_group =
            RespondentGroupAction.replace_respondents(respondent_group, loaded_entries)

          project |> Project.touch!()
          render(conn, "show.json", respondent_group: respondent_group)

        {:error, invalid_entries} ->
          render_invalid(conn, file.filename, invalid_entries)
      end
    else
      Logger.warn("Error when creating respondent group for survey: #{inspect(survey)}")
      render_unprocessable_entity(conn)
    end
  end

  defp entries_from_csv(file) do
    if Path.extname(file.filename) == ".csv" do
      file.path
      |> File.read!()
      |> Ask.BomParser.parse()
      |> csv_rows
      |> Enum.to_list()
    end
  end

  def unused_respondents_from_survey(survey) do
    from(r in Respondent,
      where:
        r.survey_id == ^survey.id and r.disposition == :registered,
      select: r.phone_number
    )
    |> Repo.all()
  end

  defp csv_rows(csv_string) do
    csv_string
    |> String.splitter(["\r\n", "\r", "\n"])
    |> Stream.map(fn r -> r |> String.split(",") |> Enum.at(0) |> String.trim() end)
    |> Stream.filter(fn r -> String.length(r) != 0 end)
  end

  defp update_channels(id, %{"channels" => channels}) do
    RespondentGroupAction.update_channels(id, channels)
  end

  defp update_channels(_, _), do: nil

  defp render_unprocessable_entity(conn) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(AskWeb.ChangesetView)
    |> render("error.json", changeset: change(%Respondent{}, %{}))
  end

  defp render_invalid(conn, filename, invalid_entries) do
    conn
    |> put_status(:unprocessable_entity)
    |> render("invalid_entries.json", %{invalid_entries: invalid_entries, filename: filename})
  end

  defp render_invalid_import(conn, source_survey_id, error_code, data \\ %{}) do
    conn
    |> put_status(:unprocessable_entity)
    |> render("invalid_import.json", %{
      source_survey_id: source_survey_id,
      error_code: error_code,
      data: data
    })
  end

  def delete(conn, %{"id" => id}) do
    project = conn.assigns.loaded_project
    survey = conn.assigns.loaded_survey

    # Check that the respondent_group is in the survey
    group =
      survey
      |> assoc(:respondent_groups)
      |> Repo.get!(id)

    from(r in Respondent, where: r.respondent_group_id == ^id)
    |> Repo.delete_all()

    group
    |> Repo.delete!()

    survey
    |> Repo.preload([:questionnaires])
    |> Repo.preload([:quota_buckets])
    |> Repo.preload(respondent_groups: [respondent_group_channels: :channel])
    |> change
    |> Survey.update_state()
    |> Repo.update!()

    project |> Project.touch!()

    conn
    |> put_status(:ok)
    |> render("empty.json", %{})
  end

  defp find_and_check_survey_state(conn, _options) do
    %{"project_id" => project_id, "survey_id" => survey_id} = conn.params

    project =
      conn
      |> load_project_for_change(project_id)

    survey =
      project
      |> assoc(:surveys)
      |> Repo.get!(survey_id)

    if survey |> Survey.editable?() do
      assign(conn, :loaded_survey, survey)
      |> assign(:loaded_project, project)
    else
      conn
      |> render_unprocessable_entity
      |> halt()
    end
  end
end
