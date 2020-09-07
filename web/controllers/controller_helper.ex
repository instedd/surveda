defmodule Ask.ControllerHelper do
  use Ask.Web, :api_controller

  def archived_param(params) do
    case Map.get(params, "archived") do
      # When filtering it receives a string
      "true" -> true
      "false" -> false
      # When archiving and unarchiving it receives a boolean
      true -> true
      false -> false
      _ -> :error
    end
  end

  def filter_archived(query, true), do: where(query, [x], x.archived)
  def filter_archived(query, false), do: where(query, [x], not x.archived)
  def filter_archived(query, _), do: query
end
