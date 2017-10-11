defmodule Ask.RespondentStats do
  use Ask.Web, :model

  schema "respondent_stats" do
    belongs_to :survey, Ask.Survey
    field :questionnaire_id, :integer
    field :state, :string
    field :disposition, :string
    field :quota_bucket_id, :integer
    field :mode, :string
    field :count, :integer
  end

  @nilable_fields %{
    questionnaire_id: 0,
    quota_bucket_id: 0,
    mode: ""
  }

  defmacro respondent_count(params \\ []) do
    query(params, quote do Ask.RespondentStats end, [])
  end

  defp query([], quoted, []) do
    quote do
      result = unquote(quoted)
      |> select([s], fragment("CAST(? AS UNSIGNED)", sum(s.count)))
      |> Ask.Repo.one

      case result do
        nil -> 0
        _ -> result
      end
    end
  end

  defp query([], quoted, group) do
    fields = group ++ quote(do: [fragment("CAST(? AS UNSIGNED)", sum(s.count))])
    fields = {:{}, [], fields}

    quote do
      unquote(quoted)
      |> select([s], unquote(fields))
      |> Ask.Repo.all
    end
  end

  defp query([{:by, fields} | t], quoted, []) do
    # Put field into a list when passed as a single atom
    fields = case fields do
      fields when is_list(fields) -> fields
      _ -> [fields]
    end

    quoted = quote do
      unquote(quoted)
      |> group_by([s], unquote(fields))
    end

    group = fields
      |> Enum.map(fn g -> quote do field(s, unquote(g)) end end)

    query(t, quoted, group)
  end

  defp query([{:by, fields} | _], _, _) do
    raise "Grouping already specified: #{fields}"
  end

  defp query([{field, value} | t], quoted, group) do
    quoted = case value do
      nil ->
        case @nilable_fields[field] do
          nil -> raise "Field #{field} is not nilable"
          nil_value ->
            quote do
              unquote(quoted)
              |> where([s], field(s, unquote(field)) == unquote(nil_value))
            end
        end
      value ->
        quote do
          unquote(quoted)
          |> where([s], field(s, unquote(field)) == unquote(value))
        end
    end

    query(t, quoted, group)
  end
end
