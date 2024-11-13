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

    assert {:noreply, _, _} = SurveyResults.handle_cast({:respondents_results, survey.id, %RespondentsFilter{}}, nil)

    path = SurveyResults.file_path(survey, :respondents_results)
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

  test "download results csv with non-started last call" do
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

    group = insert(:respondent_group)

    respondent =
      insert(:respondent,
        survey: survey,
        hashed_number: "1asd12451eds",
        disposition: "partial",
        effective_modes: ["sms", "ivr"],
        respondent_group: group,
        stats: %Stats{
          total_received_sms: 4,
          total_sent_sms: 3,
          total_call_time_seconds: 12,
          call_durations: %{"call-3" => 45},
          attempts: %{sms: 1, mobileweb: 2, ivr: 3},
          pending_call: true
        }
      )

    insert(:response, respondent: respondent, field_name: "Smokes", value: "Yes")
    insert(:response, respondent: respondent, field_name: "Exercises", value: "No")
    insert(:response, respondent: respondent, field_name: "Perfect Number", value: "100")

    assert {:noreply, _, _} = SurveyResults.handle_cast({:respondents_results, survey.id, %RespondentsFilter{}}, nil)

    path = SurveyResults.file_path(survey, :respondents_results)
    csv = File.read!(path)

    [line1, line2, _] = csv |> String.split("\r\n")

    assert line1 ==
              "respondent_id,disposition,date,modes,user_stopped,total_sent_sms,total_received_sms,sms_attempts,total_call_time,ivr_attempts,mobileweb_attempts,section_order,sample_file,Smokes,Exercises,Perfect_Number,Question"

    line_2_ivr_attempts =
      [line2] |> Stream.map(& &1) |> CSV.decode() |> Enum.to_list() |> hd |> Enum.at(9)

    assert line_2_ivr_attempts == "2"
  end

  test "download results csv with sections" do
    project = insert(:project)

    questionnaire =
      insert(:questionnaire, name: "test", project: project, steps: @three_sections)

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
        questionnaire: questionnaire,
        hashed_number: "1asd12451eds",
        disposition: "partial",
        effective_modes: ["sms", "ivr"],
        respondent_group: group_1,
        section_order: [0, 1, 2],
        stats: %Stats{total_received_sms: 4, total_sent_sms: 3, total_call_time: 12}
      )

    insert(:response, respondent: respondent_1, field_name: "Smokes", value: "Yes")
    insert(:response, respondent: respondent_1, field_name: "Refresh", value: "No")
    insert(:response, respondent: respondent_1, field_name: "Perfect_Number", value: "4")
    insert(:response, respondent: respondent_1, field_name: "Exercises", value: "No")
    group_2 = insert(:respondent_group)

    respondent_2 =
      insert(:respondent,
        survey: survey,
        questionnaire: questionnaire,
        hashed_number: "34y5345tjyet",
        effective_modes: ["mobileweb"],
        respondent_group: group_2,
        section_order: [2, 1, 0],
        stats: %Stats{total_sent_sms: 1}
      )

    insert(:response, respondent: respondent_2, field_name: "Smokes", value: "No")

    assert {:noreply, _, _} = SurveyResults.handle_cast({:respondents_results, survey.id, %RespondentsFilter{}}, nil)
    path = SurveyResults.file_path(survey, :respondents_results)
    csv = File.read!(path)

    [line1, line2, line3, _] = csv |> String.split("\r\n")

    assert line1 ==
              "respondent_id,disposition,date,modes,user_stopped,total_sent_sms,total_received_sms,sms_attempts,total_call_time,ivr_attempts,mobileweb_attempts,section_order,sample_file,Smokes,Exercises,Refresh,Probability,Last,Perfect_Number,Question"

    [
      line_2_hashed_number,
      line_2_disp,
      _,
      line_2_modes,
      _,
      line_2_total_sent_sms,
      line_2_total_received_sms,
      _,
      line_2_total_call_time,
      _,
      _,
      line_2_section_order,
      line_2_respondent_group,
      line_2_smoke,
      line_2_exercises,
      line_2_refresh,
      _,
      _,
      line_2_perfect_number,
      _
    ] = [line2] |> Stream.map(& &1) |> CSV.decode() |> Enum.to_list() |> hd

    assert line_2_hashed_number == respondent_1.hashed_number
    assert line_2_modes == "SMS, Phone call"
    assert line_2_respondent_group == group_1.name
    assert line_2_smoke == "Yes"
    assert line_2_exercises == "No"
    assert line_2_perfect_number == "4"
    assert line_2_refresh == "No"
    assert line_2_disp == "Partial"
    assert line_2_total_sent_sms == "3"
    assert line_2_total_received_sms == "4"
    assert line_2_total_call_time == "12m 0s"
    assert line_2_section_order == "First section, Second section, Third section"

    [
      line_3_hashed_number,
      line_3_disp,
      _,
      line_3_modes,
      _,
      line_3_total_sent_sms,
      line_3_total_received_sms,
      _,
      line_3_total_call_time,
      _,
      _,
      line_3_section_order,
      line_3_respondent_group,
      line_3_smoke,
      line_3_exercises,
      line_3_refresh,
      _,
      _,
      _,
      _
    ] = [line3] |> Stream.map(& &1) |> CSV.decode() |> Enum.to_list() |> hd

    assert line_3_hashed_number == respondent_2.hashed_number
    assert line_3_modes == "Mobile Web"
    assert line_3_respondent_group == group_2.name
    assert line_3_smoke == "No"
    assert line_3_exercises == ""
    assert line_3_refresh == ""
    assert line_3_disp == "Registered"
    assert line_3_total_sent_sms == "1"
    assert line_3_total_received_sms == "0"
    assert line_3_total_call_time == "0m 0s"
    assert line_3_section_order == "Third section, Second section, First section"
  end

  test "download results csv with untitled sections" do
    project = insert(:project)

    questionnaire =
      insert(:questionnaire, name: "test", project: project, steps: @three_sections_untitled)

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
        questionnaire: questionnaire,
        hashed_number: "1asd12451eds",
        disposition: "partial",
        effective_modes: ["sms", "ivr"],
        respondent_group: group_1,
        section_order: [0, 1, 2],
        stats: %Stats{total_received_sms: 4, total_sent_sms: 3, total_call_time: 12}
      )

    group_2 = insert(:respondent_group)

    respondent_2 =
      insert(:respondent,
        survey: survey,
        questionnaire: questionnaire,
        hashed_number: "34y5345tjyet",
        effective_modes: ["mobileweb"],
        respondent_group: group_2,
        section_order: [2, 1, 0],
        stats: %Stats{total_sent_sms: 1}
      )

    insert(:response, respondent: respondent_2, field_name: "Smokes", value: "No")

    assert {:noreply, _, _} = SurveyResults.handle_cast({:respondents_results, survey.id, %RespondentsFilter{}}, nil)
    path = SurveyResults.file_path(survey, :respondents_results)
    csv = File.read!(path)

    [line1, line2, line3, _] = csv |> String.split("\r\n")

    assert line1 ==
              "respondent_id,disposition,date,modes,user_stopped,total_sent_sms,total_received_sms,sms_attempts,total_call_time,ivr_attempts,mobileweb_attempts,section_order,sample_file,Smokes,Exercises,Refresh,Probability,Last,Perfect_Number,Question"

    [
      line_2_hashed_number,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      line_2_section_order,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _
    ] = [line2] |> Stream.map(& &1) |> CSV.decode() |> Enum.to_list() |> hd

    assert line_2_hashed_number == respondent_1.hashed_number
    assert line_2_section_order == "Untitled 1, Second section, Untitled 3"

    [
      line_3_hashed_number,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      line_3_section_order,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _
    ] = [line3] |> Stream.map(& &1) |> CSV.decode() |> Enum.to_list() |> hd

    assert line_3_hashed_number == respondent_2.hashed_number
    assert line_3_section_order == "Untitled 3, Second section, Untitled 1"
  end

  test "download results csv with filter by disposition" do
    project = insert(:project)
    questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)

    survey =
      insert(:survey,
        project: project,
        cutoff: 4,
        questionnaires: [questionnaire],
        state: :ready,
        schedule: completed_schedule()
      )

    group_1 = insert(:respondent_group)

    respondent_1 =
      insert(:respondent,
        survey: survey,
        hashed_number: "1asd12451eds",
        disposition: "partial",
        effective_modes: ["sms", "ivr"],
        respondent_group: group_1
      )

    insert(:response, respondent: respondent_1, field_name: "Smokes", value: "Yes")
    insert(:response, respondent: respondent_1, field_name: "Exercises", value: "No")

    respondent_2 =
      insert(:respondent,
        survey: survey,
        hashed_number: "34y5345tjyet",
        effective_modes: ["mobileweb"]
      )

    insert(:response, respondent: respondent_2, field_name: "Smokes", value: "No")

    filter = %RespondentsFilter{disposition: :registered}
    assert {:noreply, _, _} = SurveyResults.handle_cast({:respondents_results, survey.id, filter}, nil)
    path = SurveyResults.file_path(survey, {:respondents_results, filter})
    csv = File.read!(path)

    [line1, line2, _] = csv |> String.split("\r\n")

    assert line1 ==
              "respondent_id,disposition,date,modes,user_stopped,total_sent_sms,total_received_sms,sms_attempts,section_order,sample_file,Smokes,Exercises,Perfect_Number,Question"

    [
      line_2_hashed_number,
      line_2_disp,
      _,
      line_2_modes,
      _,
      _,
      _,
      _,
      _,
      line_2_respondent_group,
      line_2_smoke,
      line_2_exercises,
      _,
      _
    ] = [line2] |> Stream.map(& &1) |> CSV.decode() |> Enum.to_list() |> hd

    assert line_2_hashed_number == respondent_2.hashed_number
    assert line_2_modes == "Mobile Web"
    assert line_2_respondent_group == group_1.name
    assert line_2_smoke == "No"
    assert line_2_exercises == ""
    assert line_2_disp == "Registered"
  end

  test "download results csv with filter by update timestamp" do
    project = insert(:project)
    questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)

    survey =
      insert(:survey,
        project: project,
        cutoff: 4,
        questionnaires: [questionnaire],
        state: :ready,
        schedule: completed_schedule()
      )

    group_1 = insert(:respondent_group)

    respondent_1 =
      insert(:respondent,
        survey: survey,
        hashed_number: "1asd12451eds",
        disposition: "partial",
        effective_modes: ["sms", "ivr"],
        respondent_group: group_1
      )

    insert(:response, respondent: respondent_1, field_name: "Smokes", value: "Yes")
    insert(:response, respondent: respondent_1, field_name: "Exercises", value: "No")
    group_2 = insert(:respondent_group)

    respondent_2 =
      insert(:respondent,
        survey: survey,
        hashed_number: "34y5345tjyet",
        effective_modes: ["mobileweb"],
        respondent_group: group_2,
        updated_at: Timex.shift(Timex.now(), hours: 2, minutes: 3)
      )

    insert(:response, respondent: respondent_2, field_name: "Smokes", value: "No")

    filter = %RespondentsFilter{since: Timex.shift(Timex.now(), hours: 2)}
    assert {:noreply, _, _} = SurveyResults.handle_cast({:respondents_results, survey.id, filter}, nil)
    path = SurveyResults.file_path(survey, {:respondents_results, filter})
    csv = File.read!(path)

    [line1, line2, _] = csv |> String.split("\r\n")

    assert line1 ==
              "respondent_id,disposition,date,modes,user_stopped,total_sent_sms,total_received_sms,sms_attempts,section_order,sample_file,Smokes,Exercises,Perfect_Number,Question"

    [
      line_2_hashed_number,
      line_2_disp,
      _,
      line_2_modes,
      _,
      _,
      _,
      _,
      _,
      line_2_respondent_group,
      line_2_smoke,
      line_2_exercises,
      _,
      _
    ] = [line2] |> Stream.map(& &1) |> CSV.decode() |> Enum.to_list() |> hd

    assert line_2_hashed_number == respondent_2.hashed_number
    assert line_2_modes == "Mobile Web"
    assert line_2_respondent_group == group_1.name
    assert line_2_smoke == "No"
    assert line_2_exercises == ""
    assert line_2_disp == "Registered"
  end

  test "download results csv with filter by final state" do
    project = insert(:project)
    questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)

    survey =
      insert(:survey,
        project: project,
        cutoff: 4,
        questionnaires: [questionnaire],
        state: :ready,
        schedule: completed_schedule()
      )

    group_1 = insert(:respondent_group)

    respondent_1 =
      insert(:respondent,
        survey: survey,
        hashed_number: "1asd12451eds",
        disposition: "partial",
        effective_modes: ["sms", "ivr"],
        respondent_group: group_1,
        state: "completed"
      )

    insert(:response, respondent: respondent_1, field_name: "Smokes", value: "Yes")
    insert(:response, respondent: respondent_1, field_name: "Exercises", value: "No")

    respondent_2 =
      insert(:respondent,
        survey: survey,
        hashed_number: "34y5345tjyet",
        effective_modes: ["mobileweb"]
      )

    insert(:response, respondent: respondent_2, field_name: "Smokes", value: "No")

    filter = %RespondentsFilter{state: :completed}
    assert {:noreply, _, _} = SurveyResults.handle_cast({:respondents_results, survey.id, filter}, nil)
    path = SurveyResults.file_path(survey, {:respondents_results, filter})
    csv = File.read!(path)

    [line1, line2, _] = csv |> String.split("\r\n")

    assert line1 ==
              "respondent_id,disposition,date,modes,user_stopped,total_sent_sms,total_received_sms,sms_attempts,section_order,sample_file,Smokes,Exercises,Perfect_Number,Question"

    [
      line_2_hashed_number,
      line_2_disp,
      _,
      line_2_modes,
      _,
      _,
      _,
      _,
      _,
      line_2_respondent_group,
      line_2_smoke,
      line_2_exercises,
      _,
      _
    ] = [line2] |> Stream.map(& &1) |> CSV.decode() |> Enum.to_list() |> hd

    assert line_2_hashed_number == respondent_1.hashed_number
    assert line_2_modes == "SMS, Phone call"
    assert line_2_respondent_group == group_1.name
    assert line_2_smoke == "Yes"
    assert line_2_exercises == "No"
    assert line_2_disp == "Partial"
  end

  test "download results csv with sample file column and two different respondent groups" do
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

    group_1 = insert(:respondent_group, name: "respondent_group_1_example.csv")

    respondent_1 =
      insert(:respondent,
        survey: survey,
        hashed_number: "1asd12451eds",
        disposition: "partial",
        effective_modes: ["sms", "ivr"],
        respondent_group: group_1,
        stats: %Stats{total_received_sms: 4, total_sent_sms: 3, total_call_time: 12}
      )

    insert(:response, respondent: respondent_1, field_name: "Smokes", value: "Yes")
    insert(:response, respondent: respondent_1, field_name: "Exercises", value: "No")
    group_2 = insert(:respondent_group, name: "respondent_group_2_example.csv")

    respondent_2 =
      insert(:respondent,
        survey: survey,
        hashed_number: "34y5345tjyet",
        effective_modes: ["mobileweb"],
        respondent_group: group_2,
        stats: %Stats{total_sent_sms: 1}
      )

    insert(:response, respondent: respondent_2, field_name: "Smokes", value: "No")

    respondent_3 =
      insert(:respondent,
        survey: survey,
        hashed_number: "1hsd13451ftj",
        disposition: "partial",
        effective_modes: ["sms", "ivr"],
        respondent_group: group_1,
        stats: %Stats{total_received_sms: 4, total_sent_sms: 3, total_call_time: 12}
      )

    insert(:response, respondent: respondent_3, field_name: "Smokes", value: "Yes")
    insert(:response, respondent: respondent_3, field_name: "Exercises", value: "No")

    respondent_4 =
      insert(:respondent,
        survey: survey,
        hashed_number: "67y5634tjsdfg",
        disposition: "partial",
        effective_modes: ["sms", "ivr"],
        respondent_group: group_2,
        stats: %Stats{total_received_sms: 4, total_sent_sms: 3, total_call_time: 12}
      )

    insert(:response, respondent: respondent_4, field_name: "Smokes", value: "Yes")
    insert(:response, respondent: respondent_4, field_name: "Exercises", value: "No")

    assert {:noreply, _, _} = SurveyResults.handle_cast({:respondents_results, survey.id, %RespondentsFilter{}}, nil)
    path = SurveyResults.file_path(survey, :respondents_results)
    csv = File.read!(path)

    assert !String.contains?(group_1.name, [" ", ",", "*", ":", "?", "\\", "|", "/", "<", ">"])
    assert !String.contains?(group_2.name, [" ", ",", "*", ":", "?", "\\", "|", "/", "<", ">"])

    [line1, line2, line3, line4, line5, _] = csv |> String.split("\r\n")

    assert line1 ==
              "respondent_id,disposition,date,modes,user_stopped,total_sent_sms,total_received_sms,sms_attempts,total_call_time,ivr_attempts,mobileweb_attempts,section_order,sample_file,Smokes,Exercises,Perfect_Number,Question"

    [
      line_2_hashed_number,
      _,
      _,
      line_2_modes,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      line_2_respondent_group,
      _,
      _,
      _,
      _
    ] = [line2] |> Stream.map(& &1) |> CSV.decode() |> Enum.to_list() |> hd

    assert line_2_hashed_number == respondent_1.hashed_number
    assert line_2_modes == "SMS, Phone call"
    assert line_2_respondent_group == group_1.name

    [
      line_3_hashed_number,
      _,
      _,
      line_3_modes,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      line_3_respondent_group,
      _,
      _,
      _,
      _
    ] = [line3] |> Stream.map(& &1) |> CSV.decode() |> Enum.to_list() |> hd

    assert line_3_hashed_number == respondent_2.hashed_number
    assert line_3_modes == "Mobile Web"
    assert line_3_respondent_group == group_2.name

    [
      line_4_hashed_number,
      _,
      _,
      line_4_modes,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      line_4_respondent_group,
      _,
      _,
      _,
      _
    ] = [line4] |> Stream.map(& &1) |> CSV.decode() |> Enum.to_list() |> hd

    assert line_4_hashed_number == respondent_3.hashed_number
    assert line_4_modes == "SMS, Phone call"
    assert line_4_respondent_group == group_1.name

    [
      line_5_hashed_number,
      _,
      _,
      line_5_modes,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      line_5_respondent_group,
      _,
      _,
      _,
      _
    ] = [line5] |> Stream.map(& &1) |> CSV.decode() |> Enum.to_list() |> hd

    assert line_5_hashed_number == respondent_4.hashed_number
    assert line_5_modes == "SMS, Phone call"
    assert line_5_respondent_group == group_2.name
  end

  test "download results csv with comparisons" do
    project = insert(:project)
    questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)

    questionnaire2 =
      insert(:questionnaire, name: "test 2", project: project, steps: @dummy_steps)

    survey =
      insert(:survey,
        project: project,
        cutoff: 4,
        questionnaires: [questionnaire, questionnaire2],
        state: :ready,
        schedule: completed_schedule(),
        comparisons: [
          %{"mode" => ["sms"], "questionnaire_id" => questionnaire.id, "ratio" => 50},
          %{"mode" => ["sms"], "questionnaire_id" => questionnaire2.id, "ratio" => 50}
        ]
      )

    group_1 = insert(:respondent_group)

    respondent_1 =
      insert(:respondent,
        survey: survey,
        questionnaire_id: questionnaire.id,
        mode: ["sms"],
        respondent_group: group_1,
        disposition: "partial",
        stats: %Stats{attempts: %{sms: 2}}
      )

    insert(:response, respondent: respondent_1, field_name: "Smokes", value: "Yes")
    insert(:response, respondent: respondent_1, field_name: "Perfect_Number", value: "No")

    respondent_2 =
      insert(:respondent,
        survey: survey,
        questionnaire_id: questionnaire2.id,
        mode: ["sms", "ivr"],
        respondent_group: group_1,
        disposition: "completed",
        stats: %Stats{attempts: %{sms: 5}}
      )

    insert(:response, respondent: respondent_2, field_name: "Smokes", value: "No")

    assert {:noreply, _, _} = SurveyResults.handle_cast({:respondents_results, survey.id, %RespondentsFilter{}}, nil)
    path = SurveyResults.file_path(survey, :respondents_results)
    csv = File.read!(path)

    [line1, line2, line3, _] = csv |> String.split("\r\n")

    assert line1 ==
              "respondent_id,disposition,date,modes,user_stopped,total_sent_sms,total_received_sms,sms_attempts,section_order,sample_file,variant,Smokes,Exercises,Perfect_Number,Question"

    [
      line_2_hashed_number,
      line_2_disp,
      _,
      _,
      _,
      _,
      _,
      line_2_sms_attempts,
      _,
      _,
      line_2_variant,
      line_2_smoke,
      _,
      line_2_number,
      _
    ] = [line2] |> Stream.map(& &1) |> CSV.decode() |> Enum.to_list() |> hd

    assert line_2_hashed_number == respondent_1.hashed_number |> to_string
    assert line_2_smoke == "Yes"
    assert line_2_number == "No"
    assert line_2_variant == "test - SMS"
    assert line_2_disp == "Partial"
    assert line_2_sms_attempts == "2"

    [
      line_3_hashed_number,
      line_3_disp,
      _,
      _,
      _,
      _,
      _,
      line_3_sms_attempts,
      _,
      _,
      line_3_variant,
      line_3_smoke,
      _,
      line_3_number,
      _
    ] = [line3] |> Stream.map(& &1) |> CSV.decode() |> Enum.to_list() |> hd

    assert line_3_hashed_number == respondent_2.hashed_number |> to_string
    assert line_3_smoke == "No"
    assert line_3_number == ""
    assert line_3_variant == "test 2 - SMS with phone call fallback"
    assert line_3_disp == "Completed"
    assert line_3_sms_attempts == "5"
  end

  test "download csv with language" do
    languageStep = %{
      "id" => "1234-5678",
      "type" => "language-selection",
      "title" => "Language selection",
      "store" => "language",
      "prompt" => %{
        "sms" => "1 for English, 2 for Spanish",
        "ivr" => %{
          "text" => "1 para ingles, 2 para español",
          "audioSource" => "tts"
        }
      },
      "language_choices" => ["en", "es"]
    }

    steps = [languageStep]

    project = insert(:project)
    questionnaire = insert(:questionnaire, name: "test", project: project, steps: steps)

    survey =
      insert(:survey,
        project: project,
        cutoff: 4,
        questionnaires: [questionnaire],
        state: :ready,
        schedule: completed_schedule()
      )

    group_1 = insert(:respondent_group)

    respondent_1 =
      insert(:respondent,
        survey: survey,
        hashed_number: "1asd12451eds",
        disposition: "partial",
        respondent_group: group_1
      )

    insert(:response, respondent: respondent_1, field_name: "language", value: "es")

    assert {:noreply, _, _} = SurveyResults.handle_cast({:respondents_results, survey.id, %RespondentsFilter{}}, nil)
    path = SurveyResults.file_path(survey, :respondents_results)
    csv = File.read!(path)

    [line1, line2, _] = csv |> String.split("\r\n")

    assert line1 ==
              "respondent_id,disposition,date,modes,user_stopped,total_sent_sms,total_received_sms,sms_attempts,section_order,sample_file,language"

    [line_2_hashed_number, _, _, _, _, _, _, _, _, _, line_2_language] =
      [line2] |> Stream.map(& &1) |> CSV.decode() |> Enum.to_list() |> hd

    assert line_2_hashed_number == respondent_1.hashed_number
    assert line_2_language == "español"
  end

  test "download disposition history csv" do
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

    respondent_1 =
      insert(:respondent, survey: survey, hashed_number: "1asd12451eds", disposition: "partial")

    respondent_2 = insert(:respondent, survey: survey, hashed_number: "34y5345tjyet")

    insert(:respondent_disposition_history,
      survey: survey,
      respondent: respondent_1,
      respondent_hashed_number: respondent_1.hashed_number,
      disposition: "partial",
      mode: "sms",
      inserted_at: cast!("2000-01-01T01:02:03Z")
    )

    insert(:respondent_disposition_history,
      survey: survey,
      respondent: respondent_1,
      respondent_hashed_number: respondent_1.hashed_number,
      disposition: "completed",
      mode: "sms",
      inserted_at: cast!("2000-01-01T02:03:04Z")
    )

    insert(:respondent_disposition_history,
      survey: survey,
      respondent: respondent_2,
      respondent_hashed_number: respondent_2.hashed_number,
      disposition: "partial",
      mode: "ivr",
      inserted_at: cast!("2000-01-01 03:04:05Z")
    )

    insert(:respondent_disposition_history,
      survey: survey,
      respondent: respondent_2,
      respondent_hashed_number: respondent_2.hashed_number,
      disposition: "completed",
      mode: "ivr",
      inserted_at: cast!("2000-01-01 04:05:06Z")
    )

    assert {:noreply, _, _} = SurveyResults.handle_cast({:disposition_history, survey.id, %RespondentsFilter{}}, nil)
    path = SurveyResults.file_path(survey, :disposition_history)
    csv = File.read!(path)

    lines = csv |> String.split("\r\n") |> Enum.reject(fn x -> String.length(x) == 0 end)

    assert lines == [
              "Respondent ID,Disposition,Mode,Timestamp",
              "1asd12451eds,partial,SMS,2000-01-01 01:02:03 UTC",
              "1asd12451eds,completed,SMS,2000-01-01 02:03:04 UTC",
              "34y5345tjyet,partial,Phone call,2000-01-01 03:04:05 UTC",
              "34y5345tjyet,completed,Phone call,2000-01-01 04:05:06 UTC"
            ]
  end

  test "download incentives" do
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

    completed_at = cast!("2019-11-10T09:00:00Z")

    insert(:respondent,
      survey: survey,
      phone_number: "1234",
      disposition: "partial",
      questionnaire_id: questionnaire.id,
      mode: ["sms"]
    )

    insert(:respondent,
      survey: survey,
      phone_number: "5678",
      disposition: "completed",
      questionnaire_id: questionnaire.id,
      mode: ["sms", "ivr"],
      completed_at: completed_at
    )

    insert(:respondent,
      survey: survey,
      phone_number: "9012",
      disposition: "completed",
      mode: ["sms", "ivr"]
    )

    insert(:respondent,
      survey: survey,
      phone_number: "4321",
      disposition: "completed",
      questionnaire_id: questionnaire.id,
      mode: ["ivr"]
    )

    assert {:noreply, _, _} = SurveyResults.handle_cast({:incentives, survey.id, %RespondentsFilter{}}, nil)
    path = SurveyResults.file_path(survey, :incentives)
    csv = File.read!(path)

    lines = csv |> String.split("\r\n") |> Enum.reject(fn x -> String.length(x) == 0 end)

    assert lines == [
              "Telephone number,Questionnaire-Mode,Completion date",
              "5678,test - SMS with phone call fallback,2019-11-10 09:00:00 UTC",
              "4321,test - Phone call,"
            ]
  end
end
