defmodule AskWeb.ControllerHelper do
  use AskWeb, :api_controller

  def archived_param(params, source, required \\ false)

  def archived_param(params, source, true = _required) do
    case archived_param(params, source, false) do
      true -> true
      false -> false
      _other -> :error
    end
  end

  def archived_param(params, "body_json" = _source, false = _required) do
    case Map.get(params, "archived") do
      true -> true
      false -> false
      other -> other
    end
  end

  def archived_param(params, "url" = _source, false = _required) do
    case Map.get(params, "archived") do
      "true" -> true
      "false" -> false
      other -> other
    end
  end

  def filter_archived(query, true), do: where(query, [x], x.archived)
  def filter_archived(query, false), do: where(query, [x], not x.archived)
  def filter_archived(query, _), do: query
end
