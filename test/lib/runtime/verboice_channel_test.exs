defmodule Ask.Runtime.VerboiceChannelTest do
  use Ask.ConnCase
  use Ask.DummySteps
  use Timex

  alias Ask.{Respondent, BrokerStub, Survey}
  alias Ask.Runtime.{VerboiceChannel, Flow, ReplyHelper, SurveyLogger, Broker}

  require Ask.Runtime.ReplyHelper

  @survey %{schedule: Ask.Schedule.always()}

  defp trim_xml(xml) do
    xml |> String.replace("\t", "") |> String.replace("\n", "")
  end

  setup %{conn: conn} do
    GenServer.start_link(BrokerStub, [], name: BrokerStub.server_ref)
    respondent = insert(:respondent, phone_number: "123", state: "active")
    {
      :ok,
      conn: conn,
      respondent: respondent,
      tts_step: {:prompts, [Ask.StepBuilder.tts_prompt("Do you exercise?")]},
      # Triple of "digits", step spec, and expected TwiML output
      twiml_map: [
        {Flow.Message.answer, {:reply, ReplyHelper.simple("Step", Ask.StepBuilder.tts_prompt("Do you exercise?"))}, "<Say>Do you exercise?</Say>"},
        {Flow.Message.reply("8"), {:reply, ReplyHelper.simple("Step", Ask.StepBuilder.tts_prompt("Do you exercise?"))}, "<Say>Do you exercise?</Say>"},
        {Flow.Message.answer, {:reply, ReplyHelper.multiple([{"Hello!", Ask.StepBuilder.tts_prompt("Hello!")}, {"Do you exercise", Ask.StepBuilder.tts_prompt("Do you exercise?")}])}, "<Response><Say>Hello!</Say><Gather action=\"http://app.ask.dev/callbacks/verboice?respondent=#{respondent.id}\" finishOnKey=\"\"><Say>Do you exercise?</Say></Gather><Redirect>http://app.ask.dev/callbacks/verboice?respondent=#{respondent.id}&amp;Digits=timeout</Redirect></Response>"},
        {Flow.Message.answer, {:reply, ReplyHelper.simple("Step", Ask.StepBuilder.audio_prompt(uuid: "foo", text: "Do you exercise?"))}, "<Response><Gather action=\"http://app.ask.dev/callbacks/verboice?respondent=#{respondent.id}\" finishOnKey=\"\"><Play>http://app.ask.dev/audio/foo</Play></Gather><Redirect>http://app.ask.dev/callbacks/verboice?respondent=#{respondent.id}&amp;Digits=timeout</Redirect></Response>"},
        {Flow.Message.answer, {:reply, ReplyHelper.simple_with_num_digits("Step", Ask.StepBuilder.audio_prompt(uuid: "foo", text: "Do you exercise?"), 3)}, "<Response><Gather action=\"http://app.ask.dev/callbacks/verboice?respondent=#{respondent.id}\" finishOnKey=\"\" numDigits=\"3\"><Play>http://app.ask.dev/audio/foo</Play></Gather><Redirect>http://app.ask.dev/callbacks/verboice?respondent=#{respondent.id}&amp;Digits=timeout</Redirect></Response>"},
        {Flow.Message.answer, :end, "<Response><Hangup/></Response>"},
        {Flow.Message.answer, {:end, {:reply, ReplyHelper.quota_completed(Ask.StepBuilder.tts_prompt("Bye!"))}}, "<Response><Say>Bye!</Say><Hangup/></Response>"},
        {Flow.Message.answer, {:reply, ReplyHelper.simple("Step", Ask.StepBuilder.audio_prompt(uuid: "foo", text: "Do you exercise?"))}, "<Play>http://app.ask.dev/audio/foo</Play>"},
        {Flow.Message.reply("8"), {:reply, ReplyHelper.simple("Step", Ask.StepBuilder.audio_prompt(uuid: "foo", text: "Do you exercise?"))}, "<Play>http://app.ask.dev/audio/foo</Play>"},
      ]
    }
  end

  test "callbacks", %{conn: conn, respondent: respondent, twiml_map: twiml_map} do
    respondent_id = respondent.id

    Enum.each(twiml_map, fn
      {flow_message, step, twiml} ->
        GenServer.cast(BrokerStub.server_ref, {:expects, fn
          {:sync_step, %Respondent{id: ^respondent_id}, ^flow_message, "ivr"} -> step
        end})

        digits = case flow_message do
          :answer -> nil
          {:reply, digits } -> digits
        end

        conn = VerboiceChannel.callback(conn, %{"respondent" => respondent_id, "Digits" => digits}, BrokerStub)
        response_twiml = response(conn, 200) |> trim_xml
        assert response_twiml =~ twiml
      end)
  end

  test "callback respondent not found", %{conn: conn} do
    conn = VerboiceChannel.callback(conn, %{"respondent" => 0})
    assert response(conn, 200) |> trim_xml == "<Response><Hangup/></Response>"
  end

  test "callback without respondent", %{conn: conn} do
    conn = VerboiceChannel.callback(conn, %{})
    assert response(conn, 200) |> trim_xml == "<Response><Hangup/></Response>"
  end

  describe "channel sync" do
    test "create channels" do
      user = insert(:user)
      user_id = user.id
      VerboiceChannel.sync_channels(user.id, "http://test.com", ["foo", "bar"])
      channels = user |> assoc(:channels) |> where([c], c.provider == "verboice" and c.base_url == "http://test.com") |> Repo.all
      assert [
        %Ask.Channel{user_id: ^user_id, provider: "verboice", base_url: "http://test.com", type: "ivr", name: "foo", settings: %{"verboice_channel" => "foo"}},
        %Ask.Channel{user_id: ^user_id, provider: "verboice", base_url: "http://test.com", type: "ivr", name: "bar", settings: %{"verboice_channel" => "bar"}}
      ] = channels
    end

    test "delete channels" do
      user = insert(:user)
      channel = insert(:channel, user: user, provider: "verboice", base_url: "http://test.com", name: "foo", settings: %{"verboice_channel" => "foo"})
      VerboiceChannel.sync_channels(user.id, "http://test.com", ["bar"])
      refute Ask.Channel |> Repo.get(channel.id)
    end

    test "don't delete channels of other providers" do
      user = insert(:user)
      channel = insert(:channel, user: user, provider: "other", base_url: "http://test.com", name: "foo")
      VerboiceChannel.sync_channels(user.id, "http://test.com", [])
      assert Ask.Channel |> Repo.get(channel.id)
    end

    test "leave existing channels untouched" do
      user = insert(:user)
      channel = insert(:channel, user: user, provider: "verboice", base_url: "http://test.com", name: "FOO", settings: %{"verboice_channel" => "foo"})
      channel = Ask.Channel |> Repo.get(channel.id)
      VerboiceChannel.sync_channels(user.id, "http://test.com", ["foo"])
      channels = user |> assoc(:channels) |> where([c], c.provider == "verboice") |> Repo.all
      assert [^channel] = channels
    end
  end

  describe "process_call_response" do
    test "creates new state" do
      new_state = VerboiceChannel.process_call_response({:ok, %{"call_id" => 123}})
      assert new_state == {:ok, %{verboice_call_id: 123}}
    end

    test "returns error on response error" do
      new_state = VerboiceChannel.process_call_response(:error)
      assert new_state == {:error, :error}
    end
  end

  describe "status callback" do
    test "with code and reason", %{conn: conn} do
      test_channel = Ask.TestChannel.new(false, false)

      channel = insert(:channel, settings: test_channel |> Ask.TestChannel.settings, type: "ivr")
      quiz = insert(:questionnaire, steps: @dummy_steps)
      survey = insert(:survey, Map.merge(@survey, %{state: "running", questionnaires: [quiz], mode: [["ivr"]]}))
      group = insert(:respondent_group, survey: survey, respondents_count: 1) |> Repo.preload(:channels)

      Ask.RespondentGroupChannel.changeset(%Ask.RespondentGroupChannel{}, %{respondent_group_id: group.id, channel_id: channel.id, mode: "ivr"}) |> Repo.insert

      respondent = insert(:respondent, survey: survey, respondent_group: group)

      {:ok, logger} = SurveyLogger.start_link
      {:ok, broker} = Broker.start_link
      Broker.poll

      survey = Repo.get(Survey, survey.id)
      assert survey.state == "running"

      respondent = Repo.get(Respondent, respondent.id)
      assert respondent.state == "active"

      VerboiceChannel.callback(conn, %{"path" => ["status", respondent.id, "token"], "CallStatus" => "failed", "CallStatusReason" => "some random reason", "CallStatusCode" => "42"})

      :ok = logger |> GenServer.stop

      assert [enqueueing, call_failed] = (respondent |> Repo.preload(:survey_log_entries)).survey_log_entries

      assert enqueueing.survey_id == survey.id
      assert enqueueing.action_data == "Enqueueing call"
      assert enqueueing.action_type == "contact"

      assert call_failed.survey_id == survey.id
      assert call_failed.action_data == "some random reason (42)"
      assert call_failed.action_type == "contact"

      :ok = broker |> GenServer.stop
    end

    test "with only code", %{conn: conn} do
      test_channel = Ask.TestChannel.new(false, false)
      channel = insert(:channel, settings: test_channel |> Ask.TestChannel.settings, type: "ivr")
      quiz = insert(:questionnaire, steps: @dummy_steps)
      survey = insert(:survey, Map.merge(@survey, %{state: "running", questionnaires: [quiz], mode: [["ivr"]]}))
      group = insert(:respondent_group, survey: survey, respondents_count: 1) |> Repo.preload(:channels)

      Ask.RespondentGroupChannel.changeset(%Ask.RespondentGroupChannel{}, %{respondent_group_id: group.id, channel_id: channel.id, mode: "ivr"}) |> Repo.insert

      respondent = insert(:respondent, survey: survey, respondent_group: group)

      {:ok, logger} = SurveyLogger.start_link
      {:ok, broker} = Broker.start_link
      Broker.poll

      survey = Repo.get(Survey, survey.id)
      assert survey.state == "running"

      respondent = Repo.get(Respondent, respondent.id)
      assert respondent.state == "active"

      VerboiceChannel.callback(conn, %{"path" => ["status", respondent.id, "token"], "CallStatus" => "failed", "CallStatusCode" => "42"})

      :ok = logger |> GenServer.stop

      assert [enqueueing, call_failed] = (respondent |> Repo.preload(:survey_log_entries)).survey_log_entries

      assert enqueueing.survey_id == survey.id
      assert enqueueing.action_data == "Enqueueing call"
      assert enqueueing.action_type == "contact"

      assert call_failed.survey_id == survey.id
      assert call_failed.action_data == "(42)"
      assert call_failed.action_type == "contact"

      :ok = broker |> GenServer.stop
    end

    test "with only reason", %{conn: conn} do
      test_channel = Ask.TestChannel.new(false, false)

      channel = insert(:channel, settings: test_channel |> Ask.TestChannel.settings, type: "ivr")
      quiz = insert(:questionnaire, steps: @dummy_steps)
      survey = insert(:survey, Map.merge(@survey, %{state: "running", questionnaires: [quiz], mode: [["ivr"]]}))
      group = insert(:respondent_group, survey: survey, respondents_count: 1) |> Repo.preload(:channels)

      Ask.RespondentGroupChannel.changeset(%Ask.RespondentGroupChannel{}, %{respondent_group_id: group.id, channel_id: channel.id, mode: "ivr"}) |> Repo.insert

      respondent = insert(:respondent, survey: survey, respondent_group: group)

      {:ok, logger} = SurveyLogger.start_link
      {:ok, broker} = Broker.start_link
      Broker.poll

      survey = Repo.get(Survey, survey.id)
      assert survey.state == "running"

      respondent = Repo.get(Respondent, respondent.id)
      assert respondent.state == "active"

      VerboiceChannel.callback(conn, %{"path" => ["status", respondent.id, "token"], "CallStatus" => "failed", "CallStatusReason" => "some random reason"})

      :ok = logger |> GenServer.stop

      assert [enqueueing, call_failed] = (respondent |> Repo.preload(:survey_log_entries)).survey_log_entries

      assert enqueueing.survey_id == survey.id
      assert enqueueing.action_data == "Enqueueing call"
      assert enqueueing.action_type == "contact"

      assert call_failed.survey_id == survey.id
      assert call_failed.action_data == "some random reason"
      assert call_failed.action_type == "contact"

      :ok = broker |> GenServer.stop
    end

    test "only failed", %{conn: conn} do
      test_channel = Ask.TestChannel.new(false, false)

      channel = insert(:channel, settings: test_channel |> Ask.TestChannel.settings, type: "ivr")
      quiz = insert(:questionnaire, steps: @dummy_steps)
      survey = insert(:survey, Map.merge(@survey, %{state: "running", questionnaires: [quiz], mode: [["ivr"]]}))
      group = insert(:respondent_group, survey: survey, respondents_count: 1) |> Repo.preload(:channels)

      Ask.RespondentGroupChannel.changeset(%Ask.RespondentGroupChannel{}, %{respondent_group_id: group.id, channel_id: channel.id, mode: "ivr"}) |> Repo.insert

      respondent = insert(:respondent, survey: survey, respondent_group: group)

      {:ok, logger} = SurveyLogger.start_link
      {:ok, broker} = Broker.start_link
      Broker.poll

      survey = Repo.get(Survey, survey.id)
      assert survey.state == "running"

      respondent = Repo.get(Respondent, respondent.id)
      assert respondent.state == "active"

      VerboiceChannel.callback(conn, %{"path" => ["status", respondent.id, "token"], "CallStatus" => "failed"})

      :ok = logger |> GenServer.stop

      assert [enqueueing, call_failed] = (respondent |> Repo.preload(:survey_log_entries)).survey_log_entries

      assert enqueueing.survey_id == survey.id
      assert enqueueing.action_data == "Enqueueing call"
      assert enqueueing.action_type == "contact"

      assert call_failed.survey_id == survey.id
      assert call_failed.action_data == "failed"
      assert call_failed.action_type == "contact"

      :ok = broker |> GenServer.stop
    end

    test "no-answer with reason and code", %{conn: conn} do
      test_channel = Ask.TestChannel.new(false, false)

      channel = insert(:channel, settings: test_channel |> Ask.TestChannel.settings, type: "ivr")
      quiz = insert(:questionnaire, steps: @dummy_steps)
      survey = insert(:survey, Map.merge(@survey, %{state: "running", questionnaires: [quiz], mode: [["ivr"]]}))
      group = insert(:respondent_group, survey: survey, respondents_count: 1) |> Repo.preload(:channels)

      Ask.RespondentGroupChannel.changeset(%Ask.RespondentGroupChannel{}, %{respondent_group_id: group.id, channel_id: channel.id, mode: "ivr"}) |> Repo.insert

      respondent = insert(:respondent, survey: survey, respondent_group: group)

      {:ok, logger} = SurveyLogger.start_link
      {:ok, broker} = Broker.start_link
      Broker.poll

      survey = Repo.get(Survey, survey.id)
      assert survey.state == "running"

      respondent = Repo.get(Respondent, respondent.id)
      assert respondent.state == "active"

      VerboiceChannel.callback(conn, %{"path" => ["status", respondent.id, "token"], "CallStatus" => "no-answer", "CallStatusReason" => "another reason", "CallStatusCode" => "foo"})

      :ok = logger |> GenServer.stop

      assert [enqueueing, call_failed] = (respondent |> Repo.preload(:survey_log_entries)).survey_log_entries

      assert enqueueing.survey_id == survey.id
      assert enqueueing.action_data == "Enqueueing call"
      assert enqueueing.action_type == "contact"

      assert call_failed.survey_id == survey.id
      assert call_failed.action_data == "no-answer: another reason (foo)"
      assert call_failed.action_type == "contact"

      :ok = broker |> GenServer.stop
    end

    test "busy with reason and code", %{conn: conn} do
      test_channel = Ask.TestChannel.new(false, false)

      channel = insert(:channel, settings: test_channel |> Ask.TestChannel.settings, type: "ivr")
      quiz = insert(:questionnaire, steps: @dummy_steps)
      survey = insert(:survey, Map.merge(@survey, %{state: "running", questionnaires: [quiz], mode: [["ivr"]]}))
      group = insert(:respondent_group, survey: survey, respondents_count: 1) |> Repo.preload(:channels)

      Ask.RespondentGroupChannel.changeset(%Ask.RespondentGroupChannel{}, %{respondent_group_id: group.id, channel_id: channel.id, mode: "ivr"}) |> Repo.insert

      respondent = insert(:respondent, survey: survey, respondent_group: group)

      {:ok, logger} = SurveyLogger.start_link
      {:ok, broker} = Broker.start_link
      Broker.poll

      survey = Repo.get(Survey, survey.id)
      assert survey.state == "running"

      respondent = Repo.get(Respondent, respondent.id)
      assert respondent.state == "active"

      VerboiceChannel.callback(conn, %{"path" => ["status", respondent.id, "token"], "CallStatus" => "busy", "CallStatusReason" => "yet another reason", "CallStatusCode" => "bar"})

      :ok = logger |> GenServer.stop

      assert [enqueueing, call_failed] = (respondent |> Repo.preload(:survey_log_entries)).survey_log_entries

      assert enqueueing.survey_id == survey.id
      assert enqueueing.action_data == "Enqueueing call"
      assert enqueueing.action_type == "contact"

      assert call_failed.survey_id == survey.id
      assert call_failed.action_data == "busy: yet another reason (bar)"
      assert call_failed.action_type == "contact"

      :ok = broker |> GenServer.stop
    end
  end
end
