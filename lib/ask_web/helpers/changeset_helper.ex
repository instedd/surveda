defmodule Changeset.Helper do
  def changed_properties(changeset) do
    changes = changeset.changes
    Enum.filter(Map.keys(changes), fn key -> changes[key] != [] end)
  end
end
