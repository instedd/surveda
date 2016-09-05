defmodule Ask.Factory do
  use ExMachina.Ecto, repo: Ask.Repo

  def user_factory do
    %Ask.User{
      email: sequence(:email, &"email-#{&1}@example.com")
    }
  end

  def project_factory do
    %Ask.Project{
      user: build(:user),
      name: sequence(:project, &"Project #{&1}")
    }
  end

  def survey_factory do
    %Ask.Survey{
      project: build(:project),
      name: sequence(:survey, &"Survey #{&1}")
    }
  end

  def questionnaire_factory do
    %Ask.Questionnaire{
      project: build(:project),
      name: sequence(:questionnaire, &"Questionnaire #{&1}"),
      description: "Description"
    }
  end

  def channel_factory do
    %Ask.Channel{
      user: build(:user),
      name: "My Channel",
      type: "sms",
      provider: "provider",
      settings: %{}
    }
  end
end
