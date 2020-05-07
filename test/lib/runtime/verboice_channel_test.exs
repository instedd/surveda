defmodule Ask.Runtime.VerboiceChannelTest do
  use Ask.ConnCase
  use Ask.DummySteps
  use Timex

  alias Ask.{Respondent, Survey, RetryStat, Stats}
  alias Ask.Runtime.{VerboiceChannel, Flow, ReplyHelper, SurveyLogger, Broker, ChannelStatusServer, SurveyStub}

  require Ask.Runtime.ReplyHelper

  @survey %{schedule: Ask.Schedule.always()}

  defp trim_xml(xml) do
    xml |> String.replace("\t", "") |> String.replace("\n", "")
  end

  setup %{conn: conn} do
    GenServer.start_link(SurveyStub, [], name: SurveyStub.server_ref)
    ChannelStatusServer.start_link
    Ask.Config.start_link()
    respondent = insert(:respondent, phone_number: "123", state: "active", session: %{"current_mode" => %{"mode" => "ivr"}})
    {
      :ok,
      conn: conn,
      respondent: respondent,
      tts_step: {:prompts, [Ask.StepBuilder.tts_prompt("Do you exercise?")]},
      # Triple of "digits", step spec, and expected TwiML output
      twiml_map: [
        {Flow.Message.answer, {:reply, ReplyHelper.simple("Step", Ask.StepBuilder.tts_prompt("Do you exercise?")), nil}, "<Say>Do you exercise?</Say>"},
        {Flow.Message.reply("8"), {:reply, ReplyHelper.simple("Step", Ask.StepBuilder.tts_prompt("Do you exercise?")), nil}, "<Say>Do you exercise?</Say>"},
        {Flow.Message.answer, {:reply, ReplyHelper.multiple([{"Hello!", Ask.StepBuilder.tts_prompt("Hello!")}, {"Do you exercise", Ask.StepBuilder.tts_prompt("Do you exercise?")}]), nil}, "<Response><Say>Hello!</Say><Gather action=\"#{Ask.Endpoint.url}/callbacks/verboice?respondent=#{respondent.id}\" finishOnKey=\"\"><Say>Do you exercise?</Say></Gather><Redirect>#{Ask.Endpoint.url}/callbacks/verboice?respondent=#{respondent.id}&amp;Digits=timeout</Redirect></Response>"},
        {Flow.Message.answer, {:reply, ReplyHelper.simple("Step", Ask.StepBuilder.audio_prompt(uuid: "foo", text: "Do you exercise?")), nil}, "<Response><Gather action=\"#{Ask.Endpoint.url}/callbacks/verboice?respondent=#{respondent.id}\" finishOnKey=\"\"><Play>#{Ask.Endpoint.url}/audio/foo.mp3</Play></Gather><Redirect>#{Ask.Endpoint.url}/callbacks/verboice?respondent=#{respondent.id}&amp;Digits=timeout</Redirect></Response>"},
        {Flow.Message.answer, {:reply, ReplyHelper.simple_with_num_digits("Step", Ask.StepBuilder.audio_prompt(uuid: "foo", text: "Do you exercise?"), 3), nil}, "<Response><Gather action=\"#{Ask.Endpoint.url}/callbacks/verboice?respondent=#{respondent.id}\" finishOnKey=\"\" numDigits=\"3\"><Play>#{Ask.Endpoint.url}/audio/foo.mp3</Play></Gather><Redirect>#{Ask.Endpoint.url}/callbacks/verboice?respondent=#{respondent.id}&amp;Digits=timeout</Redirect></Response>"},
        {Flow.Message.answer, {:end, nil}, "<Response><Hangup/></Response>"},
        {Flow.Message.answer, {:end, {:reply, ReplyHelper.quota_completed(Ask.StepBuilder.tts_prompt("Bye!"))}, nil}, "<Response><Say>Bye!</Say><Hangup/></Response>"},
        {Flow.Message.answer, {:reply, ReplyHelper.simple("Step", Ask.StepBuilder.audio_prompt(uuid: "foo", text: "Do you exercise?")), nil}, "<Play>#{Ask.Endpoint.url}/audio/foo.mp3</Play>"},
        {Flow.Message.reply("8"), {:reply, ReplyHelper.simple("Step", Ask.StepBuilder.audio_prompt(uuid: "foo", text: "Do you exercise?")), nil}, "<Play>#{Ask.Endpoint.url}/audio/foo.mp3</Play>"},
      ]
    }
  end

  test "callbacks", %{conn: conn, respondent: respondent, twiml_map: twiml_map} do
    respondent_id = respondent.id

    Enum.each(twiml_map, fn
      {flow_message, step, twiml} ->
        GenServer.cast(SurveyStub.server_ref, {:expects, fn
          {:sync_step, %Respondent{id: ^respondent_id}, ^flow_message, "ivr"} -> step
        end})

        digits = case flow_message do
          :answer -> nil
          {:reply, digits} -> digits
        end

        conn = VerboiceChannel.callback(conn, %{"respondent" => respondent_id, "Digits" => digits}, SurveyStub)
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

  test "callback ignored if not respondent's current mode", %{conn: conn, respondent: respondent} do
    respondent |> Respondent.changeset(%{session: %{"current_mode" => %{"mode" => "sms"}}}) |> Repo.update

    conn = VerboiceChannel.callback(conn, %{"respondent" => respondent.id, "Digits" => nil}, SurveyStub)
    assert response(conn, 200) |> trim_xml == "<Response><Hangup/></Response>"
  end

  @channel_foo %{"id" => 1, "name" => "foo"}
  @channel_bar %{"id" => 2, "name" => "bar"}
  @channel_baz %{"id" => 3, "name" => "baz", "shared_by" => "other@user.com"}

  describe "channel sync" do
    test "create channels" do
      user = insert(:user)
      user_id = user.id
      VerboiceChannel.sync_channels(user.id, "http://test.com", [@channel_foo, @channel_bar])
      channels = Ask.Channel |> order_by([c], c.name) |> Repo.all
      assert [
        %Ask.Channel{user_id: ^user_id, provider: "verboice", base_url: "http://test.com", type: "ivr", name: "bar", settings: %{"verboice_channel" => "bar", "verboice_channel_id" => 2}},
        %Ask.Channel{user_id: ^user_id, provider: "verboice", base_url: "http://test.com", type: "ivr", name: "foo", settings: %{"verboice_channel" => "foo", "verboice_channel_id" => 1}}
      ] = channels
    end

    test "create shared channel" do
      user = insert(:user)
      user_id = user.id
      VerboiceChannel.sync_channels(user.id, "http://test.com", [@channel_foo, @channel_bar, @channel_baz])
      channels = Ask.Channel |> order_by([c], c.name) |> Repo.all
      assert [
        %Ask.Channel{user_id: ^user_id, provider: "verboice", base_url: "http://test.com", type: "ivr", name: "bar", settings: %{"verboice_channel" => "bar", "verboice_channel_id" => 2}},
        %Ask.Channel{user_id: ^user_id, provider: "verboice", base_url: "http://test.com", type: "ivr", name: "baz", settings: %{"verboice_channel" => "baz", "verboice_channel_id" => 3, "shared_by" => "other@user.com"}},
        %Ask.Channel{user_id: ^user_id, provider: "verboice", base_url: "http://test.com", type: "ivr", name: "foo", settings: %{"verboice_channel" => "foo", "verboice_channel_id" => 1}}
      ] = channels
    end

    test "delete channels" do
      user = insert(:user)
      channel = insert(:channel, user: user, provider: "verboice", base_url: "http://test.com", name: "foo", settings: %{"verboice_channel" => "foo", "verboice_channel_id" => 1})
      VerboiceChannel.sync_channels(user.id, "http://test.com", [@channel_bar])
      refute Ask.Channel |> Repo.get(channel.id)
    end

    test "don't delete channels of other providers" do
      user = insert(:user)
      channel = insert(:channel, user: user, provider: "other", base_url: "http://test.com", name: "foo")
      VerboiceChannel.sync_channels(user.id, "http://test.com", [])
      assert Ask.Channel |> Repo.get(channel.id)
    end

    test "update existing channels" do
      user = insert(:user)
      user_id = user.id
      channel = insert(:channel, user: user, provider: "verboice", base_url: "http://test.com", name: "FOO", settings: %{"verboice_channel" => "foo", "verboice_channel_id" => 1})
      channel_id = channel.id
      VerboiceChannel.sync_channels(user.id, "http://test.com", [@channel_foo])
      channels = Ask.Channel |> Repo.all
      assert [
        %Ask.Channel{id: ^channel_id, user_id: ^user_id, provider: "verboice", base_url: "http://test.com", type: "ivr", name: "foo", settings: %{"verboice_channel" => "foo", "verboice_channel_id" => 1}}
      ] = channels
    end

    test "migrate existing channels adding the verboice channel id" do
      user = insert(:user)
      user_id = user.id
      channel = insert(:channel, user: user, provider: "verboice", type: "ivr", base_url: "http://test.com", name: "foo", settings: %{"verboice_channel" => "foo"})
      channel_id = channel.id
      VerboiceChannel.sync_channels(user.id, "http://test.com", [@channel_foo])
      channels = Ask.Channel |> Repo.all
      assert [
        %Ask.Channel{id: ^channel_id, user_id: ^user_id, provider: "verboice", base_url: "http://test.com", type: "ivr", name: "foo", settings: %{"verboice_channel" => "foo", "verboice_channel_id" => 1}}
      ] = channels
    end

    test "match existing channels by id" do
      user = insert(:user)
      user_id = user.id
      channel = insert(:channel, user: user, provider: "verboice", type: "ivr", base_url: "http://test.com", name: "fooooo", settings: %{"verboice_channel" => "fooooo", "verboice_channel_id" => 1})
      channel_id = channel.id
      VerboiceChannel.sync_channels(user.id, "http://test.com", [@channel_foo])
      channels = Ask.Channel |> Repo.all
      assert [
        %Ask.Channel{id: ^channel_id, user_id: ^user_id, provider: "verboice", base_url: "http://test.com", type: "ivr", name: "foo", settings: %{"verboice_channel" => "foo", "verboice_channel_id" => 1}}
      ] = channels
    end
  end

  describe "create channel" do
    test "create channel" do
      user = insert(:user)
      user_id = user.id
      VerboiceChannel.create_channel(user, "http://test.com", @channel_foo)
      channels = Ask.Channel |> Repo.all
      assert [
        %Ask.Channel{user_id: ^user_id, provider: "verboice", base_url: "http://test.com", type: "ivr", name: "foo", settings: %{"verboice_channel" => "foo", "verboice_channel_id" => 1}}
      ] = channels
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

      VerboiceChannel.callback(conn, %{"path" => ["status", respondent.id, "token"], "CallStatus" => "failed", "CallDuration" => "10", "CallSid" => "6B8F5B7B-E412-46D3-96E1-688215F43CC3", "CallStatusReason" => "some random reason", "CallStatusCode" => "42"})

      :ok = logger |> GenServer.stop

      assert [enqueueing, call_failed, disposition_changed_to_failed] = (respondent |> Repo.preload(:survey_log_entries)).survey_log_entries

      assert enqueueing.survey_id == survey.id
      assert enqueueing.action_data == "Enqueueing call"
      assert enqueueing.action_type == "contact"
      assert enqueueing.disposition == "queued"

      assert call_failed.survey_id == survey.id
      assert call_failed.action_data == "some random reason (42)"
      assert call_failed.action_type == "contact"
      assert call_failed.disposition == "queued"

      assert disposition_changed_to_failed.survey_id == survey.id
      assert disposition_changed_to_failed.action_data == "Failed"
      assert disposition_changed_to_failed.action_type == "disposition changed"
      assert disposition_changed_to_failed.disposition == "queued"

      respondent = Repo.get(Respondent, respondent.id)
      refute respondent.stats.total_call_time
      refute respondent.stats.total_call_time_seconds
      assert respondent.stats.call_durations
      assert respondent.stats.call_durations["6B8F5B7B-E412-46D3-96E1-688215F43CC3"] == 10

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

      VerboiceChannel.callback(conn, %{"path" => ["status", respondent.id, "token"], "CallStatus" => "failed", "CallDuration" => "11", "CallSid" => "some-id", "CallStatusCode" => "42"})

      :ok = logger |> GenServer.stop

      respondent |> assert_respondent_state("some-id", 11, "(42)")

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

      VerboiceChannel.callback(conn, %{"path" => ["status", respondent.id, "token"], "CallStatus" => "failed", "CallDuration" => "12", "CallSid" => "id with spaces", "CallStatusReason" => "some random reason"})

      :ok = logger |> GenServer.stop

      respondent |> assert_respondent_state("id with spaces", 12, "some random reason")

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

      VerboiceChannel.callback(conn, %{"path" => ["status", respondent.id, "token"], "CallStatus" => "failed", "CallDuration" => "13", "CallSid" => "12345"})

      :ok = logger |> GenServer.stop

      respondent |> assert_respondent_state("12345", 13, "failed")

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

      VerboiceChannel.callback(conn, %{"path" => ["status", respondent.id, "token"], "CallStatus" => "no-answer", "CallDuration" => "14", "CallSid" => "1515", "CallStatusReason" => "another reason", "CallStatusCode" => "foo"})

      :ok = logger |> GenServer.stop

      respondent |> assert_respondent_state("1515", 14, "no-answer: another reason (foo)")

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

      VerboiceChannel.callback(conn, %{"path" => ["status", respondent.id, "token"], "CallStatus" => "busy", "CallDuration" => "15", "CallSid" => "1", "CallStatusReason" => "yet another reason", "CallStatusCode" => "bar"})

      :ok = logger |> GenServer.stop

      respondent |> assert_respondent_state("1", 15, "busy: yet another reason (bar)")

      :ok = broker |> GenServer.stop
    end

    test "call expired", %{conn: conn} do
      test_channel = Ask.TestChannel.new(false, false)

      channel = insert(:channel, settings: test_channel |> Ask.TestChannel.settings, type: "ivr")
      quiz = insert(:questionnaire, steps: @dummy_steps)
      survey = insert(:survey, Map.merge(@survey, %{state: "running", questionnaires: [quiz], mode: [["ivr"]]}))
      group = insert(:respondent_group, survey: survey, respondents_count: 1) |> Repo.preload(:channels)

      Ask.RespondentGroupChannel.changeset(%Ask.RespondentGroupChannel{}, %{respondent_group_id: group.id, channel_id: channel.id, mode: "ivr"}) |> Repo.insert

      respondent = insert(:respondent, survey: survey, respondent_group: group, stats: %Stats{total_call_time_seconds: 20})

      {:ok, logger} = SurveyLogger.start_link
      Broker.handle_info(:poll, nil, Timex.now)

      survey = Repo.get(Survey, survey.id)
      assert survey.state == "running"

      %Respondent{mode: mode} = respondent = Repo.get(Respondent, respondent.id)
      assert respondent.state == "active"

      assert 1 == %{survey_id: survey.id} |> RetryStat.stats() |> RetryStat.count(%{attempt: 1, ivr_active: true, mode: mode})

      VerboiceChannel.callback(conn, %{"path" => ["status", respondent.id, "token"], "CallStatus" => "expired", "CallDuration" => "16", "CallSid" => "b1eca8c0-9b77-4273-848f-c821b3dbbabf"})

      assert 1 == %{survey_id: survey.id} |> RetryStat.stats() |> RetryStat.count(%{attempt: 1, ivr_active: true, mode: mode}),
             "respondent should remain active when contact expired"

      :ok = logger |> GenServer.stop

      assert [enqueueing] = (respondent |> Repo.preload(:survey_log_entries)).survey_log_entries

      assert enqueueing.survey_id == survey.id
      assert enqueueing.action_data == "Enqueueing call"
      assert enqueueing.action_type == "contact"

      respondent = Repo.get(Respondent, respondent.id)
      refute respondent.stats.total_call_time
      assert respondent.stats.total_call_time_seconds == 20
      assert respondent.stats.call_durations
      assert respondent.stats.call_durations["b1eca8c0-9b77-4273-848f-c821b3dbbabf"] == 16
      assert Stats.total_call_time_seconds(respondent.stats) == 36

      VerboiceChannel.callback(conn, %{"path" => ["status", respondent.id, "token"], "CallStatus" => "expired", "CallDuration" => "16"})
    end
  end

  test "check status" do
    assert VerboiceChannel.check_status(%{
      "status" => %{
        "ok" => true,
        "messages" => nil
      }
    }) == :up

    assert VerboiceChannel.check_status(%{
      "status" => %{
        "ok" => false,
        "messages" => ["NOT FOUND"]
      }
    }) == {:down, ["NOT FOUND"]}

    assert VerboiceChannel.check_status(%{
      "enabled" => false
    }) == {:down, ["Channel is disabled"]}

    # :status should be :up when not receiving status information
    assert VerboiceChannel.check_status(%{}) == :up
  end

  describe "attempts count" do
    setup %{conn: conn} do
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

      respondent = Repo.get(Respondent, respondent.id)
      assert respondent.state == "active"

      {:ok, %{conn: conn, respondent: respondent, logger: logger, broker: broker}}
    end

    test "counts attempt upon non-expired status callback", %{conn: conn, respondent: respondent, logger: logger, broker: broker} do
      assert Stats.attempts(respondent.stats, :ivr) == 0
      VerboiceChannel.callback(conn, %{"path" => ["status", respondent.id, "token"], "CallStatus" => "failed", "CallDuration" => "0", "CallSid" => "6B8F5B7B-E412-46D3-96E1-688215F43CC3", "CallStatusReason" => "some random reason", "CallStatusCode" => "42"})
      respondent = Repo.get(Respondent, respondent.id)
      assert Stats.attempts(respondent.stats, :ivr) == 1

      logger |> GenServer.stop
      broker |> GenServer.stop
    end

    test "doesn't count attempts upon expired status callback", %{conn: conn, respondent: respondent, logger: logger, broker: broker} do
      assert Stats.attempts(respondent.stats, :ivr) == 0

      VerboiceChannel.callback(conn, %{"path" => ["status", respondent.id, "token"], "CallStatus" => "expired", "CallDuration" => "0", "CallSid" => "6B8F5B7B-E412-46D3-96E1-688215F43CC3", "CallStatusReason" => "expired", "CallStatusCode" => "2"})

      respondent = Repo.get(Respondent, respondent.id)
      assert Stats.attempts(respondent.stats, :ivr) == 0

      logger |> GenServer.stop
      broker |> GenServer.stop
    end
    
    test "counts attempt upon respondent interaction callback", %{conn: conn, respondent: respondent, logger: logger, broker: broker} do
      assert Stats.attempts(respondent.stats, :ivr) == 0

      VerboiceChannel.callback(conn, %{"respondent" => respondent.id, "Digits" => "3"})

      respondent = Repo.get(Respondent, respondent.id)
      assert Stats.attempts(respondent.stats, :ivr) == 1

      logger |> GenServer.stop
      broker |> GenServer.stop
    end
  end

  defp assert_respondent_state(respondent, call_id, expected_call_duration, call_fail_reason) do
    assert [enqueueing, call_failed, disposition_changed_to_failed] = (respondent |> Repo.preload(:survey_log_entries)).survey_log_entries

    assert enqueueing.survey_id == respondent.survey_id
    assert enqueueing.action_data == "Enqueueing call"
    assert enqueueing.action_type == "contact"
    assert enqueueing.disposition == "queued"

    assert call_failed.survey_id == respondent.survey_id
    assert call_failed.action_data == call_fail_reason
    assert call_failed.action_type == "contact"
    assert call_failed.disposition == "queued"

    assert disposition_changed_to_failed.survey_id == respondent.survey_id
    assert disposition_changed_to_failed.action_data == "Failed"
    assert disposition_changed_to_failed.action_type == "disposition changed"
    assert disposition_changed_to_failed.disposition == "queued"

    respondent = Repo.get(Respondent, respondent.id)
    refute respondent.stats.total_call_time
    refute respondent.stats.total_call_time_seconds
    assert respondent.stats.call_durations
    assert respondent.stats.call_durations[call_id] == expected_call_duration
    assert Stats.total_call_time_seconds(respondent.stats) == expected_call_duration
  end

end
