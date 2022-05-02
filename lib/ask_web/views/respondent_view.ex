defmodule AskWeb.RespondentView do
  use AskWeb, :view
  alias Ask.Respondent

  def render(
        "index.json",
        %{respondents: respondents, partial_relevant_enabled: partial_relevant_enabled} =
          render_index_data
      ) do
    %{
      data: %{
        respondents:
          render_many(respondents, AskWeb.RespondentView, "respondent.json",
            partial_relevant_enabled: partial_relevant_enabled
          )
      },
      meta: render_index_meta(render_index_data)
    }
  end

  def render("index_field.json", %{
        index_field: %{type: "fixed" = type, key: "phone_number" = key}
      }) do
    %{
      display_text: AskWeb.Gettext.gettext("Respondent ID"),
      key: key,
      type: type,
      sortable: false,
      data_type: "text"
    }
  end

  def render("index_field.json", %{index_field: %{type: "fixed" = type, key: "disposition" = key}}) do
    %{
      display_text: AskWeb.Gettext.gettext("Disposition"),
      key: key,
      type: type,
      sortable: true,
      data_type: "text"
    }
  end

  def render("index_field.json", %{index_field: %{type: "fixed" = type, key: "date" = key}}) do
    %{
      display_text: AskWeb.Gettext.gettext("Date"),
      key: key,
      type: type,
      sortable: true,
      data_type: "date"
    }
  end

  def render("index_field.json", %{index_field: %{type: "mode" = type, key: "ivr" = key}}) do
    %{
      display_text: AskWeb.Gettext.gettext("IVR Attempts"),
      key: key,
      type: type,
      sortable: false,
      data_type: "number"
    }
  end

  def render("index_field.json", %{index_field: %{type: "mode" = type, key: "sms" = key}}) do
    %{
      display_text: AskWeb.Gettext.gettext("SMS Attempts"),
      key: key,
      type: type,
      sortable: false,
      data_type: "number"
    }
  end

  def render("index_field.json", %{index_field: %{type: "mode" = type, key: "mobileweb" = key}}) do
    %{
      display_text: AskWeb.Gettext.gettext("Mobileweb Attempts"),
      key: key,
      type: type,
      sortable: false,
      data_type: "number"
    }
  end

  def render("index_field.json", %{index_field: %{type: "variant" = type, key: "variant" = key}}) do
    %{
      display_text: AskWeb.Gettext.gettext("Variant"),
      key: key,
      type: type,
      sortable: false,
      data_type: "text"
    }
  end

  def render("index_field.json", %{
        index_field: %{type: "partial_relevant" = type, key: "answered_questions" = key}
      }) do
    %{
      display_text: AskWeb.Gettext.gettext("Relevants"),
      key: key,
      type: type,
      sortable: false,
      data_type: "number"
    }
  end

  def render("index_field.json", %{index_field: %{type: type, key: key}}) do
    %{
      display_text: String.capitalize(key),
      key: key,
      type: type,
      sortable: false
    }
  end

  def render("show.json", %{respondent: respondent}) do
    %{data: render_one(respondent, AskWeb.RespondentView, "respondent.json")}
  end

  def render("empty.json", %{respondent: _respondent}) do
    %{data: %{}}
  end

  def render("respondent.json", %{
        respondent: respondent,
        partial_relevant_enabled: partial_relevant_enabled
      }) do
    date =
      case respondent.responses do
        [] -> nil
        _ -> respondent.responses |> Enum.map(fn r -> r.updated_at end) |> Enum.max()
      end

    partial_relevant_answered_count =
      if partial_relevant_enabled,
        do: Respondent.partial_relevant_answered_count(respondent, false),
        else: nil

    responses =
      render_many(respondent.responses, AskWeb.RespondentView, "response.json", as: :response)

    put_if = fn map, key, value, condition ->
      if condition, do: Map.put(map, key, value), else: map
    end

    result =
      %{
        id: respondent.id,
        phone_number: respondent.hashed_number,
        survey_id: respondent.survey_id,
        effective_modes: respondent.effective_modes,
        stats: respondent.stats,
        mode: respondent.mode,
        questionnaire_id: respondent.questionnaire_id,
        responses: responses,
        disposition: respondent.disposition,
        date: date,
        updated_at: respondent.updated_at
      }
      |> put_if.(:experiment_name, respondent.experiment_name, respondent.experiment_name)
      |> put_if.(
        :partial_relevant,
        %{answered_count: partial_relevant_answered_count},
        partial_relevant_enabled
      )

    result
  end

  def render("response.json", %{response: response}) do
    %{
      name: response.field_name,
      value: response.value
    }
  end

  def render("stats.json", %{stats: nil}) do
    %{
      data: %{
        reference: %{},
        respondents_by_disposition: %{},
        percentages: %{},
        cumulative_percentages: %{},
        completion_percentage: 0,
        attempted_respondents: 0,
        total_respondents: 0,
        target: 0
      }
    }
  end

  def render("stats.json", %{
        stats: %{
          id: id,
          respondents_by_disposition: respondents_by_disposition,
          reference: reference,
          percentages: percentages,
          cumulative_percentages: cumulative_percentages,
          attempted_respondents: attempted_respondents,
          total_respondents: total_respondents,
          target: target,
          completion_percentage: completion_percentage
        }
      }) do
    %{
      data: %{
        id: id,
        reference: reference,
        respondents_by_disposition: respondents_by_disposition,
        percentages: render_percentages(percentages),
        cumulative_percentages: render_percentages(cumulative_percentages),
        completion_percentage: completion_percentage,
        attempted_respondents: attempted_respondents,
        total_respondents: total_respondents,
        target: target
      }
    }
  end

  def render("quotas_stats.json", %{
        stats: %{
          id: id,
          reference: buckets,
          respondents_by_disposition: respondents_by_disposition,
          cumulative_percentages: cumulative_percentages,
          attempted_respondents: attempted_respondents,
          total_respondents: total_respondents,
          target: target,
          completion_percentage: completion_percentage
        }
      }) do
    %{
      data: %{
        id: id,
        respondents_by_disposition: respondents_by_disposition,
        reference: render_many(buckets, AskWeb.RespondentView, "survey_bucket.json", as: :bucket),
        cumulative_percentages:
          cumulative_percentages
          |> Enum.map(fn {questionnaire_id, date_percentages} ->
            {to_string(questionnaire_id),
             render_many(date_percentages, AskWeb.RespondentView, "date_percentages.json",
               as: :completed
             )}
          end)
          |> Enum.into(%{}),
        completion_percentage: completion_percentage,
        attempted_respondents: attempted_respondents,
        total_respondents: total_respondents,
        target: target
      }
    }
  end

  def render("survey_bucket.json", %{bucket: bucket}) do
    condition =
      bucket.condition
      |> Enum.reduce([], fn {store, value}, conditions ->
        value =
          case value do
            [lower, upper] -> "#{lower} - #{upper}"
            _ -> value
          end

        ["#{store}: #{value}" | conditions]
      end)
      |> Enum.join(" - ")

    %{
      "id" => bucket.id,
      "name" => condition
    }
  end

  def render("date_percentages.json", %{completed: {date, percentage}}) do
    %{
      date: Date.to_iso8601(date),
      percent: percentage
    }
  end

  defp render_index_meta(%{respondents_count: respondents_count, index_fields: index_fields}),
    do: %{
      count: respondents_count,
      fields:
        render_many(index_fields, AskWeb.RespondentView, "index_field.json", as: :index_field)
    }

  defp render_index_meta(%{respondents_count: respondents_count}), do: %{count: respondents_count}

  defp render_percentages(percentages) do
    percentages
    |> Enum.map(fn {id, date_percentages} ->
      {to_string(id),
       render_many(date_percentages, AskWeb.RespondentView, "date_percentages.json",
         as: :completed
       )}
    end)
    |> Enum.into(%{})
  end
end
