defmodule Ask.Repo.Migrations.MoveQuestionnaireSettingsQuotaCompletedMessageToQuotaCompletedSteps do
  use Ecto.Migration

  alias Ask.Repo

  defmodule Questionnaire do
    use AskWeb, :model

    schema "questionnaires" do
      field :steps, Ask.Ecto.Type.JSON
      field :quota_completed_steps, Ask.Ecto.Type.JSON
      field :settings, Ask.Ecto.Type.JSON
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:steps, :quota_completed_steps, :settings])
    end
  end

  def up do
    Questionnaire
    |> Repo.all()
    |> Enum.each(fn questionnaire ->
      quota_completed_message = questionnaire.settings["quota_completed_message"]

      quota_completed_steps =
        if quota_completed_message do
          [
            %{
              "id" => Ecto.UUID.generate(),
              "prompt" => quota_completed_message,
              "skip_logic" => nil,
              "title" => "Quota completed message",
              "type" => "explanation"
            }
          ]
        else
          nil
        end

      settings = Map.delete(questionnaire.settings, "quota_completed_message")

      questionnaire
      |> Questionnaire.changeset(%{
        settings: settings,
        quota_completed_steps: quota_completed_steps
      })
      |> Repo.update!()
    end)
  end

  def down do
  end
end
