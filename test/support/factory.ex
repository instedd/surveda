defmodule Ask.Factory do
  use ExMachina.Ecto, repo: Ask.Repo

  def user_factory do
    %Ask.User{
      email: sequence(:email, &"email-#{&1}@example.com"),
      encrypted_password: Addict.Configs.password_hasher.hashpwsalt "1234"
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
      modes: ["SMS", "IVR"],
      steps: [],
    }
  end

  def channel_factory do
    %Ask.Channel{
      user: build(:user),
      name: "My Channel",
      type: "sms",
      provider: "test",
      settings: %{}
    }
  end

  def survey_channel_factory do
    %Ask.SurveyChannel{
    }
  end

  def respondent_factory do
    %Ask.Respondent{
      survey: build(:survey),
      phone_number: Integer.to_string(:rand.uniform(1000000000)),
      state: "pending"
    }
  end

  def response_factory do
    %Ask.Response{
        field_name: "Smoke"
    }
  end

  def oauth_token_factory do
    %Ask.OAuthToken{
      provider: "test",
      user: build(:user),
      access_token: %{
        "access_token" => :crypto.strong_rand_bytes(27) |> Base.encode64,
      },
      expires_at: Timex.now |> Timex.add(Timex.Duration.from_hours(1))
    }
  end

end
