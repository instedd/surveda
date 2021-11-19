defmodule Ask.FloipPackage do
  import Ecto.Query
  alias Ask.{Repo, Response, Respondent}

  def id(survey) do
    survey.floip_package_id
  end

  def title(survey) do
    survey.name
  end

  def name(survey) do
    survey.id |> to_string
  end

  # "The timestamp for when this package was created/published."
  #
  # There's no point in publishing a package from Surveda before the
  # survey actually starts. Before that point, a survey is just
  # a draft which can't get responses. So, created_at(package) == survey(started_at).
  def created_at(survey) do
    DateTime.to_iso8601(survey.started_at, :extended)
  end

  # "A version control indicator for the package.
  # Timestamps are used to indicate different versions of a package's schema."
  #
  # Surveda doesn't allow changes to a questionnaire once a survey started,
  # so FLOIP package structure for a given survey is immutable,
  # so modified_at(package) == survey(started_at).
  def modified_at(survey) do
    DateTime.to_iso8601(survey.started_at, :extended)
  end

  def query_params(options) do
    start_timestamp =
      if options[:start_timestamp] do
        "filter[start-timestamp]=#{DateTime.to_iso8601(options[:start_timestamp], :extended)}"
      else
        nil
      end

    end_timestamp =
      if options[:end_timestamp] do
        "filter[end-timestamp]=#{DateTime.to_iso8601(options[:end_timestamp], :extended)}"
      else
        nil
      end

    size =
      if options[:size] do
        "page[size]=#{options[:size]}"
      else
        nil
      end

    after_cursor =
      if options[:after_cursor] do
        "page[afterCursor]=#{options[:after_cursor]}"
      else
        nil
      end

    before_cursor =
      if options[:before_cursor] do
        "page[beforeCursor]=#{options[:before_cursor]}"
      else
        nil
      end

    query =
      [start_timestamp, end_timestamp, size, after_cursor, before_cursor]
      |> Enum.filter(fn s -> s end)
      |> Enum.join("&")

    if String.length(query) > 0 do
      "?#{query}"
    else
      ""
    end
  end

  def parse_query_params(query_params) do
    options = %{}
    options =
      if query_params["filter"]["end-timestamp"] do
        {:ok, end_timestamp, _} = DateTime.from_iso8601(query_params["filter"]["end-timestamp"])
        options |> Map.put(:end_timestamp, end_timestamp)
      else
        options
      end

    options =
      if query_params["filter"]["start-timestamp"] do
        {:ok, start_timestamp, _} = DateTime.from_iso8601(query_params["filter"]["start-timestamp"])
        options |> Map.put(:start_timestamp, start_timestamp)
      else
        options
      end

    options =
      if query_params["page"]["afterCursor"] do
        {after_cursor, _} = query_params["page"]["afterCursor"] |> Integer.parse
        options |> Map.put(:after_cursor, after_cursor)
      else
        options
      end

    options =
      if query_params["page"]["beforeCursor"] do
        {before_cursor, _} = query_params["page"]["beforeCursor"] |> Integer.parse
        options |> Map.put(:before_cursor, before_cursor)
      else
        options
      end

    options =
      if query_params["page"]["size"] do
        {size, _} = query_params["page"]["size"] |> Integer.parse
        options |> Map.put(:size, size)
      else
        options
      end

    options
  end

  # Given a survey, returns its responses complying
  # with FLOIP.
  # options:
  # - start_timestamp: a string representing an ISO8601 date.
  #   If given, only responses after (exclusive) that timestamp are provided.
  # - end_timestamp: a string representing an ISO8601 date.
  #   If given, only responses before (inclusive) that timestamp are provided.
  # Responses are ordered by ID.
  # - size: The requested number of responses per pagination page
  # - after_cursor: The response row_id to requests responses after this id, when paginating forward
  # - before_cursor: The response row_id to request responses prior to this id, when paginating in reverse
  def responses(survey, options \\ %{}) do
    dynamic = true
    dynamic =
      if options[:start_timestamp] do
        start_timestamp = options[:start_timestamp]
        dynamic([r, respondent], r.inserted_at > ^start_timestamp and ^dynamic)
      else
        dynamic
      end

    dynamic =
      if options[:end_timestamp] do
        end_timestamp = options[:end_timestamp]
        dynamic([r, respondent], r.inserted_at <= ^end_timestamp and ^dynamic)
      else
        dynamic
      end

    dynamic =
      if options[:after_cursor] do
        after_cursor = options[:after_cursor]
        dynamic([r, respondent], r.id > ^after_cursor and ^dynamic)
      else
        dynamic
      end

    dynamic =
      if options[:before_cursor] do
        before_cursor = options[:before_cursor]
        dynamic([r, respondent], r.id < ^before_cursor and ^dynamic)
      else
        dynamic
      end

    query = (from r in Response,
      join: respondent in Respondent, on: r.respondent_id == respondent.id,
      where: respondent.survey_id == ^survey.id,
      where: ^dynamic,
      order_by: r.id,
      select: {r, respondent})

    query =
      if options[:size] do
        size = options[:size]
        query |> limit(^size)
      else
        query |> limit(1000)
      end

    first_response =
      query
      |> first
      |> Repo.one
      |> db_response_to_floip_response

    # TODO: do this in a sane way
    last_response =
      query
      |> Repo.all
      |> Enum.at(-1)
      |> db_response_to_floip_response

    stream =
      query
      |> Repo.stream
      |> Stream.map(fn {r, respondent} ->
        {r, respondent} |> db_response_to_floip_response
      end)

    {:ok, responses} = Repo.transaction(fn() -> Enum.to_list(stream) end)

    {responses, first_response, last_response}
  end

  def responses_for_aggregator(survey, responses) do
    %{
      data: %{
        type: "responses",
        id: id(survey),
        attributes: %{
          responses: responses
        }
      }
    }
  end

  defp db_response_to_floip_response(nil), do: nil
  defp db_response_to_floip_response({r, respondent}) do
    timestamp = DateTime.to_iso8601(r.inserted_at, :extended)
    # FLOIP needs us to define a session_id. In Surveda, each survey is only taken by a respondent
    # once, so it's safe to assume session_id == contact_id.
    [timestamp, r.id, respondent.hashed_number, respondent.hashed_number, r.field_name, r.value, %{}]
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

  # Descriptor payload of a survey's FLOIP package
  def descriptor(survey, responses_link) do
    %{
      "data" => %{
        "type" => "packages",
        "id" => id(survey),
        "attributes" => %{
          "profile" => "flow-results-package",
          "flow-results-specification" => "1.0.0-rc1",
          "created" => created_at(survey),
          "modified" => modified_at(survey),
          "id" => id(survey),
          "title" => title(survey),
          "name" => name(survey),
          "resources" => [%{
            "api-data-url" => responses_link,
            "profile" => "data-resource",
            "encoding" => "utf-8",
            "mediatype" => "application/json",
            "name" => "#{name(survey)}-data",
            "path" => nil,
            "schema" => %{
              "fields" => fields(),
              "questions" => questions(survey)
            }
          }]
        }
      }
    }
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
        "name" => "session_id",
        "title" => "Session ID",
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
