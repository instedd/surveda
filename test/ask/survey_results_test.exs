defmodule Ask.SurveyResultsTest do
  use Ask.DataCase
  use Ask.DummySteps

  alias Ask.{
    RespondentsFilter,
    Stats,
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

  test "generates results csv" do
    project = insert(:project)
    questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)

    survey =
      insert(:survey,
        project: project,
        cutoff: 4,
        questionnaires: [questionnaire],
        state: :ready,
        schedule: completed_schedule(),
        mode: [["sms", "ivr"], ["mobileweb"], ["sms", "mobileweb"]]
      )

    group_1 = insert(:respondent_group)

    respondent_1 =
      insert(:respondent,
        survey: survey,
        hashed_number: "1asd12451eds",
        disposition: "partial",
        effective_modes: ["sms", "ivr"],
        respondent_group: group_1,
        stats: %Stats{
          total_received_sms: 4,
          total_sent_sms: 3,
          total_call_time_seconds: 12,
          call_durations: %{"call-3" => 45},
          attempts: %{sms: 1, mobileweb: 2, ivr: 3},
          pending_call: false
        }
      )

    insert(:response, respondent: respondent_1, field_name: "Smokes", value: "Yes")
    insert(:response, respondent: respondent_1, field_name: "Exercises", value: "No")
    insert(:response, respondent: respondent_1, field_name: "Perfect Number", value: "100")
    group_2 = insert(:respondent_group)

    respondent_2 =
      insert(:respondent,
        survey: survey,
        hashed_number: "34y5345tjyet",
        effective_modes: ["mobileweb"],
        respondent_group: group_2,
        stats: %Stats{total_sent_sms: 1},
        user_stopped: true
      )

    insert(:response, respondent: respondent_2, field_name: "Smokes", value: "No")

    assert {:noreply, _, _} = SurveyResults.handle_cast({:respondent_result, survey.id, %RespondentsFilter{}}, nil)

    path = SurveyResults.file_path(survey, :respondent_result)
    csv = File.read!(path)

    [line1, line2, line3, _] = csv |> String.split("\r\n")

    assert line1 ==
              "respondent_id,disposition,date,modes,user_stopped,total_sent_sms,total_received_sms,sms_attempts,total_call_time,ivr_attempts,mobileweb_attempts,section_order,sample_file,Smokes,Exercises,Perfect_Number,Question"

    [
      line_2_hashed_number,
      line_2_disp,
      _,
      line_2_modes,
      line_2_user_stopped,
      line_2_total_sent_sms,
      line_2_total_received_sms,
      line_2_sms_attempts,
      line_2_total_call_time,
      line_2_ivr_attempts,
      line_2_mobileweb_attempts,
      line_2_section_order,
      line_2_respondent_group,
      line_2_smoke,
      line_2_exercises,
      line_2_perfect_number,
      _
    ] = [line2] |> Stream.map(& &1) |> CSV.decode() |> Enum.to_list() |> hd

    assert line_2_hashed_number == respondent_1.hashed_number
    assert line_2_modes == "SMS, Phone call"
    assert line_2_respondent_group == group_1.name
    assert line_2_smoke == "Yes"
    assert line_2_exercises == "No"
    assert line_2_disp == "Partial"
    assert line_2_total_sent_sms == "3"
    assert line_2_total_received_sms == "4"
    assert line_2_total_call_time == "0m 57s"
    assert line_2_perfect_number == "100"
    assert line_2_section_order == ""
    assert line_2_sms_attempts == "1"
    assert line_2_mobileweb_attempts == "2"
    assert line_2_ivr_attempts == "3"
    assert line_2_user_stopped == "false"

    [
      line_3_hashed_number,
      line_3_disp,
      _,
      line_3_modes,
      line_3_user_stopped,
      line_3_total_sent_sms,
      line_3_total_received_sms,
      line_3_sms_attempts,
      line_3_total_call_time,
      line_3_ivr_attempts,
      line_3_mobileweb_attempts,
      line_3_section_order,
      line_3_respondent_group,
      line_3_smoke,
      line_3_exercises,
      _,
      _
    ] = [line3] |> Stream.map(& &1) |> CSV.decode() |> Enum.to_list() |> hd

    assert line_3_hashed_number == respondent_2.hashed_number
    assert line_3_modes == "Mobile Web"
    assert line_3_respondent_group == group_2.name
    assert line_3_smoke == "No"
    assert line_3_exercises == ""
    assert line_3_disp == "Registered"
    assert line_3_total_sent_sms == "1"
    assert line_3_total_received_sms == "0"
    assert line_3_total_call_time == "0m 0s"
    assert line_3_section_order == ""
    assert line_3_sms_attempts == "0"
    assert line_3_mobileweb_attempts == "0"
    assert line_3_ivr_attempts == "0"
    assert line_3_user_stopped == "true"
  end
end
