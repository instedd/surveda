defmodule Ask.Repo.Migrations.DeleteInvalidPropertiesFromSteps do
  use Ecto.Migration
  alias Ask.Repo
  alias ExJsonSchema.Schema

  defmodule Questionnaire do
    use Ask.Web, :model

    schema "questionnaires" do
      field :steps, Ask.Ecto.Type.JSON
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:steps])
    end
  end

  def up do
    json_schema =
      File.read!("#{Application.app_dir(:ask)}/priv/schema.json")
      |> Poison.decode!()
      |> Schema.resolve()

    Questionnaire
    |> Repo.all()
    |> Enum.each(fn q ->
      q
      |> Questionnaire.changeset(%{steps: fix_questionnaire(q.steps, json_schema)})
      |> Repo.update!()
    end)
  end

  def down do
  end

  defp fix_questionnaire(steps, json_schema) do
    steps |> Enum.map(fn step -> fix_step(step, json_schema) end)
  end

  defp fix_step(step = %{"type" => type}, json_schema) do
    properties =
      json_schema
      |> Schema.get_ref_schema([:root, "definitions", type])
      |> Map.get("properties")
      |> Map.keys()

    step
    |> Map.take(properties)
  end
end
