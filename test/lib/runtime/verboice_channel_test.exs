defmodule Ask.Runtime.VerboiceChannelTest do
  use Ask.ConnCase
  use Ask.DummySteps

  alias Ask.{Respondent, BrokerStub}
  alias Ask.Runtime.{VerboiceChannel, Flow}

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
        {Flow.Message.answer, {:prompts, [Ask.StepBuilder.tts_prompt("Do you exercise?")]}, "<Say>Do you exercise?</Say>"},
        {Flow.Message.reply("8"), {:prompts, [Ask.StepBuilder.tts_prompt("Do you exercise?")]}, "<Say>Do you exercise?</Say>"},
        {Flow.Message.answer, {:prompts, [Ask.StepBuilder.tts_prompt("Hello!"), Ask.StepBuilder.tts_prompt("Do you exercise?")]}, "<Response><Say>Hello!</Say><Gather action=\"http://app.ask.dev/callbacks/verboice?respondent=#{respondent.id}\" finishOnKey=\"\"><Say>Do you exercise?</Say></Gather><Redirect>http://app.ask.dev/callbacks/verboice?respondent=#{respondent.id}&amp;Digits=timeout</Redirect></Response>"},
        {Flow.Message.answer, {:prompts, [Ask.StepBuilder.audio_prompt(uuid: "foo", text: "Do you exercise?")]}, "<Response><Gather action=\"http://app.ask.dev/callbacks/verboice?respondent=#{respondent.id}\" finishOnKey=\"\"><Play>http://app.ask.dev/audio/foo</Play></Gather><Redirect>http://app.ask.dev/callbacks/verboice?respondent=#{respondent.id}&amp;Digits=timeout</Redirect></Response>"},
        {Flow.Message.answer, :end, "<Response><Hangup/></Response>"},
        {Flow.Message.answer, {:end, {:prompts, [Ask.StepBuilder.tts_prompt("Bye!")]}}, "<Response><Say>Bye!</Say><Hangup/></Response>"},
        {Flow.Message.answer, {:prompts, [Ask.StepBuilder.audio_prompt(uuid: "foo", text: "Do you exercise?")]}, "<Play>http://app.ask.dev/audio/foo</Play>"},
        {Flow.Message.reply("8"), {:prompts, [Ask.StepBuilder.audio_prompt(uuid: "foo", text: "Do you exercise?")]}, "<Play>http://app.ask.dev/audio/foo</Play>"},
      ]
    }
  end

  test "callbacks", %{conn: conn, respondent: respondent, twiml_map: twiml_map} do
    respondent_id = respondent.id

    Enum.each(twiml_map, fn
      {flow_message, step, twiml} ->
        GenServer.cast(BrokerStub.server_ref, {:expects, fn
          {:sync_step, %Respondent{id: ^respondent_id}, ^flow_message} -> step
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
      VerboiceChannel.sync_channels(user.id, ["foo", "bar"])
      channels = user |> assoc(:channels) |> where([c], c.provider == "verboice") |> Repo.all
      assert [
        %Ask.Channel{user_id: ^user_id, provider: "verboice", type: "ivr", name: "foo", settings: %{"verboice_channel" => "foo"}},
        %Ask.Channel{user_id: ^user_id, provider: "verboice", type: "ivr", name: "bar", settings: %{"verboice_channel" => "bar"}}
      ] = channels
    end

    test "delete channels" do
      user = insert(:user)
      channel = insert(:channel, user: user, provider: "verboice", name: "foo", settings: %{"verboice_channel" => "foo"})
      VerboiceChannel.sync_channels(user.id, ["bar"])
      refute Ask.Channel |> Repo.get(channel.id)
    end

    test "don't delete channels of other providers" do
      user = insert(:user)
      channel = insert(:channel, user: user, provider: "other", name: "foo")
      VerboiceChannel.sync_channels(user.id, [])
      assert Ask.Channel |> Repo.get(channel.id)
    end

    test "leave existing channels untouched" do
      user = insert(:user)
      channel = insert(:channel, user: user, provider: "verboice", name: "FOO", settings: %{"verboice_channel" => "foo"})
      channel = Ask.Channel |> Repo.get(channel.id)
      VerboiceChannel.sync_channels(user.id, ["foo"])
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
end
