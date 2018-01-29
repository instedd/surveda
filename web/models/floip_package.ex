defmodule Ask.FloipPackage do
  import Ecto.Query
  alias Ask.{Repo, Response, Respondent}

  # "The timestamp for when this package was created/published."
  #
  # There's no point in publishing a package from Surveda before the
  # survey actually starts. Before that point, a survey is just
  # a draft which can't get responses. So, created_at(package) == survey(started_at).
  def created_at(survey) do
    survey.started_at
  end

  # "A version control indicator for the package.
  # Timestamps are used to indicate different versions of a package's schema."
  #
  # Surveda doesn't allow changes to a questionnaire once a survey started,
  # so FLOIP package structure for a given survey is immutable,
  # so modified_at(package) == survey(started_at).
  def modified_at(survey) do
    survey.started_at
  end

  # Given a survey, returns its responses complying
  # with FLOIP.
  # Responses are ordered by ID.
  def responses(survey) do
    stream = (from r in Response,
      join: respondent in Respondent,
      where: respondent.survey_id == ^survey.id and r.respondent_id == respondent.id,
      order_by: r.id,
      select: {r, respondent})
      |> Repo.stream
      |> Stream.map(fn {r, respondent} ->
        timestamp = DateTime.to_iso8601(r.inserted_at, :extended)
        [timestamp, r.id, respondent.hashed_number, r.field_name, r.value, %{}]
      end)

    {:ok, responses} = Repo.transaction(fn() -> Enum.to_list(stream) end)

    responses
  end

  # Maps a survey's steps to FLOIP questions.
  # Note that at the moment only multiple choice and numeric
  # steps are translatable. Other step types are filtered out.
  def questions(survey) do
    survey = survey |> Repo.preload(:questionnaires)

    survey.questionnaires
    |> Enum.flat_map(fn(q) -> q.steps end)
    |> Enum.filter(&floip_question?/1)
    |> Enum.reduce(%{}, fn(step, acc) -> Map.put(acc, step["store"], to_floip_question(step)) end)
  end

  # Maps a survey step to a FLOIP question.
  # Note that at the moment only multiple choice
  # or numeric are supported, calling this with other step types
  # will raise.
  def to_floip_question(step = %{"type" => "multiple-choice"}) do
    choices = step["choices"]
    |> Enum.map(fn(choice) -> choice["value"] end)

    %{
      "type" => "select_one",
      "label" => step["title"],
      "type_options" => %{
        "choices" => choices
      }
    }
  end

  def to_floip_question(step = %{"type" => "numeric"}) do
    %{
      "type" => "numeric",
      "label" => step["title"],
      "type_options" => %{}
    }
  end

  # Whether a survey step is going to be exported as
  # a FLOIP question.
  def floip_question?(step) do
    ["multiple-choice", "numeric"]
    |> Enum.member?(step["type"])
  end

  # FLOIP mandatory fields.
  def fields() do
    [
      %{
        "name" => "timestamp",
        "title" => "Timestamp",
        "type" => "datetime"
      },
      %{
        "name" => "row_id",
        "title" => "Row ID",
        "type" => "string"
      },
      %{
        "name" => "contact_id",
        "title" => "Contact ID",
        "type" => "string"
      },
      %{
        "name" => "question_id",
        "title" => "Question ID",
        "type" => "string"
      },
      %{
        "name" => "response_id",
        "title" => "Response ID",
        "type" => "any"
      },
      %{
        "name" => "response_metadata",
        "title" => "Response Metadata",
        "type" => "object"
      }
    ]
  end
end