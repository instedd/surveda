defmodule Ask.SurveyResultsTest do
  use Ask.DataCase

  alias Ask.{
    SurveyLogEntry,
    SurveyResults,
  }

  defp cast!(str) do
    case DateTime.from_iso8601(str) do
      {:ok, datetime, _offset} -> datetime
      {:error, x} -> {:error, x}
    end
  end

  defp completed_schedule() do
    Ask.Schedule.always()
  end

  test "generates empty interactions file" do
    survey = insert(:survey)
    assert {:noreply, _, _} = SurveyResults.handle_cast({:interactions, survey.id, nil}, nil)
    path = SurveyResults.file_path(survey, :interactions)
    assert "ID,Respondent ID,Mode,Channel,Disposition,Action Type,Action Data,Timestamp\r\n" == File.read!(path)
  end

  test "generates interactions with data" do
    project = insert(:project)
    questionnaire = insert(:questionnaire, name: "test", project: project)

    survey =
      insert(:survey,
        project: project,
        cutoff: 4,
        questionnaires: [questionnaire],
        state: :ready,
        schedule: completed_schedule()
      )

    channel_1 = insert(:channel, name: "test_channel_ivr",  type: "ivr")
    group_1 = insert(:respondent_group, survey: survey)
    insert(:respondent_group_channel, respondent_group: group_1, channel: channel_1, mode: "ivr")

    channel_2 = insert(:channel, name: "test_channel_sms",  type: "sms")
    group_2 = insert(:respondent_group, survey: survey)
    insert(:respondent_group_channel, respondent_group: group_2, channel: channel_2, mode: "sms")

    channel_3 = insert(:channel, name: "test_channel_mobile_web",  type: "mobileweb")
    group_3 = insert(:respondent_group, survey: survey)
    insert(:respondent_group_channel, respondent_group: group_3, channel: channel_3, mode: "mobileweb")

    respondent_1 = insert(:respondent, survey: survey, hashed_number: "1234", respondent_group: group_1)
    respondent_2 = insert(:respondent, survey: survey, hashed_number: "5678", respondent_group: group_2)
    respondent_3 = insert(:respondent, survey: survey, hashed_number: "8901", respondent_group: group_3)

    for _ <- 1..200 do
      insert(:survey_log_entry,
        survey: survey,
        mode: "ivr",
        respondent: respondent_1,
        respondent_hashed_number: "1234",
        channel: nil,
        disposition: "partial",
        action_type: "contact",
        action_data: "explanation",
        timestamp: cast!("2000-01-01T02:03:04Z")
      )

      insert(:survey_log_entry,
        survey: survey,
        mode: "sms",
        respondent: respondent_2,
        respondent_hashed_number: "5678",
        channel: channel_2,
        disposition: "completed",
        action_type: "prompt",
        action_data: "explanation",
        timestamp: cast!("2000-01-01T01:02:03Z")
      )

      insert(:survey_log_entry,
        survey: survey,
        mode: "mobileweb",
        respondent: respondent_3,
        respondent_hashed_number: "8901",
        channel: channel_3,
        disposition: "partial",
        action_type: "contact",
        action_data: "explanation",
        timestamp: cast!("2000-01-01T03:04:05Z")
      )
    end

    assert {:noreply, _, _} = SurveyResults.handle_cast({:interactions, survey.id, nil}, nil)

    respondent_1_interactions_ids =
      Repo.all(
        from entry in SurveyLogEntry,
          where: entry.respondent_id == ^respondent_1.id,
          order_by: entry.id,
          select: entry.id
      )

    respondent_2_interactions_ids =
      Repo.all(
        from entry in SurveyLogEntry,
          where: entry.respondent_id == ^respondent_2.id,
          order_by: entry.id,
          select: entry.id
      )
    respondent_3_interactions_ids =
      Repo.all(
        from entry in SurveyLogEntry,
          where: entry.respondent_id == ^respondent_3.id,
          order_by: entry.id,
          select: entry.id
      )

    expected_list =
      List.flatten([
        "ID,Respondent ID,Mode,Channel,Disposition,Action Type,Action Data,Timestamp",
        for i <- 0..199 do
          interaction_id = respondent_1_interactions_ids |> Enum.at(i)
          "#{interaction_id},1234,IVR,,Partial,Contact attempt,explanation,2000-01-01 02:03:04 UTC"
        end,
        for i <- 0..199 do
          interaction_id_sms = respondent_2_interactions_ids |> Enum.at(i)
          "#{interaction_id_sms},5678,SMS,test_channel_sms,Completed,Prompt,explanation,2000-01-01 01:02:03 UTC"
        end,
        for i <- 0..199 do
          interaction_id_web = respondent_3_interactions_ids |> Enum.at(i)
          "#{interaction_id_web},8901,Mobile Web,test_channel_mobile_web,Partial,Contact attempt,explanation,2000-01-01 03:04:05 UTC"
        end
      ])

    path = SurveyResults.file_path(survey, :interactions)
    lines = File.read!(path) |> String.split("\r\n") |> Enum.reject(fn x -> String.length(x) == 0 end)
    assert length(lines) == length(expected_list)
    assert lines == expected_list
  end
end
