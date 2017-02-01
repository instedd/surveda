defmodule Ask.Factory do
  use ExMachina.Ecto, repo: Ask.Repo

  def audio_factory do
    %Ask.Audio{
      uuid: Ecto.UUID.generate,
      filename: "test_audio.mp3",
      data: File.read!("test/fixtures/audio.mp3")
    }
  end

  def user_factory do
    %Ask.User{
      name: "John",
      email: sequence(:email, &"email-#{&1}@example.com"),
      settings: %{},
      password_hash: "$2b$12$m0Ftkllx0UK4/bgtbNlV0eVRbxMzbUVtGtOnihUveAZnqNwSG7y6i", # 1234
      confirmed_at: Ecto.DateTime.utc
    }
  end

  def project_factory do
    %Ask.Project{
      name: sequence(:project, &"Project #{&1}"),
      salt: Ecto.UUID.generate
    }
  end

  def survey_factory do
    %Ask.Survey{
      project: build(:project),
      schedule_start_time: Ecto.Time.cast!("09:00:00"),
      schedule_end_time: Ecto.Time.cast!("18:00:00"),
      name: sequence(:survey, &"Survey #{&1}"),
      timezone: "UTC",
      mode: [["sms"]]
    }
  end

  def quota_bucket_factory do
    %Ask.QuotaBucket{
      survey: build(:survey),
      condition: %{foo: "bar"},
      quota: :rand.uniform(100)
    }
  end

  def questionnaire_factory do
    %Ask.Questionnaire{
      project: build(:project),
      name: sequence(:questionnaire, &"Questionnaire #{&1}"),
      modes: ["sms", "ivr"],
      steps: [],
      default_language: "en",
      quota_completed_msg: %{
        "en" => %{
          "sms" => "Quota completed",
          "ivr" => %{
            "audio_source" => "tts",
            "text" => "Quota completed (ivr)"
          }
        }
      },
      error_msg: %{
        "en" => %{
          "sms" => "You have entered an invalid answer",
          "ivr" => %{
            "audio_source" => "tts",
            "text" => "You have entered an invalid answer (ivr)"
          }
        }
      },
      languages: []
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

  def respondent_group_channel_factory do
    %Ask.RespondentGroupChannel{
    }
  end

  def project_membership_factory do
    %Ask.ProjectMembership{
    }
  end

  def invite_factory do
    %Ask.Invite{
    }
  end

  def respondent_group_factory do
    %Ask.RespondentGroup{
      survey: build(:survey),
      name: "Respondent Group",
      sample: [],
      respondents_count: 0,
    }
  end

  def respondent_factory do
    phone_number = "#{Integer.to_string(:rand.uniform(100))} #{Integer.to_string(:rand.uniform(100))} #{Integer.to_string(:rand.uniform(100))}"
    respondent_group = build(:respondent_group)
    %Ask.Respondent{
      respondent_group: respondent_group,
      survey: (respondent_group |> Ask.Repo.preload(:survey)).survey,
      phone_number: phone_number,
      sanitized_phone_number: Ask.Respondent.sanitize_phone_number(phone_number),
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
