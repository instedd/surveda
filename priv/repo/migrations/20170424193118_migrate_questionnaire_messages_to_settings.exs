defmodule Ask.Repo.Migrations.MigrateQuestionnaireMessagesToSettings do
  use Ecto.Migration
  alias Ask.Repo

  defmodule Questionnaire do
    use AskWeb, :model

    schema "questionnaires" do
      field :settings, Ask.Ecto.Type.JSON
      field :quota_completed_msg, Ask.Ecto.Type.JSON
      field :error_msg, Ask.Ecto.Type.JSON
      field :mobile_web_sms_message, :string
      field :mobile_web_survey_is_over_message, :string
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [
        :settings,
        :quota_completed_msg,
        :error_msg,
        :mobile_web_sms_message,
        :mobile_web_survey_is_over_message
      ])
    end
  end

  def up do
    for q <- Repo.all(Questionnaire) do
      settings = %{
        "quota_completed_message" => q.quota_completed_msg,
        "error_message" => q.error_msg,
        "mobile_web_sms_message" => q.mobile_web_sms_message,
        "mobile_web_survey_is_over_message" => q.mobile_web_survey_is_over_message
      }

      Questionnaire.changeset(q, %{"settings" => settings}) |> Repo.update!()
    end
  end

  def down do
    for q <- Repo.all(Questionnaire) do
      Questionnaire.changeset(q, %{
        "quota_completed_msg" => q.settings["quota_completed_message"],
        "error_msg" => q.settings["error_message"],
        "mobile_web_sms_message" => q.settings["mobile_web_sms_message"],
        "mobile_web_survey_is_over_message" => q.settings["mobile_web_survey_is_over_message"]
      })
      |> Repo.update!()
    end
  end
end
