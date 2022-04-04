defmodule Pagination.Helper do
  import Ecto.Query

  def conditional_limit(query, limit) do
    case limit do
      "" -> query
      number -> query |> limit(^number)
    end
  end

  def conditional_page(query, limit, page) do
    limit_number =
      case limit do
        "" ->
          10

        _ ->
          {limit_value, _} = Integer.parse(limit)
          limit_value
      end

    case page do
      "" ->
        query

      _ ->
        {page_number, _} = Integer.parse(page)
        offset = limit_number * (page_number - 1)
        query |> offset(^offset)
    end
  end
end
