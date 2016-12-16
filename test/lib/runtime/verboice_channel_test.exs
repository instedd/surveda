defmodule Ask.Runtime.VerboiceChannelTest do
  use Ask.ConnCase
  use Ask.DummySteps

  alias Ask.Respondent
  alias Ask.Runtime.{Broker, VerboiceChannel, Flow}

  defmodule BrokerStub do
    use GenServer

    def handle_cast({:expects, matcher}, _) do
      {:noreply, matcher}
    end

    def handle_call(call, _from, matcher) do
      {:reply, matcher.(call), matcher}
    end
  end

  setup %{conn: conn} do
    GenServer.start_link(BrokerStub, [], name: Broker.server_ref)
    respondent = insert(:respondent, phone_number: "123", state: "active")
    {
      :ok,
      conn: conn,
      respondent: respondent,
      tts_step: {:prompt, Ask.StepBuilder.tts_prompt("Do you exercise?")},
      # Triple of "digits", step spec, and expected TwiML output
      twiml_map: [
        {Flow.Message.answer, {:prompt, Ask.StepBuilder.tts_prompt("Do you exercise?")},"<Say>Do you exercise?</Say>"},
        {Flow.Message.reply("8"), {:prompt, Ask.StepBuilder.tts_prompt("Do you exercise?")},"<Say>Do you exercise?</Say>"},
        {Flow.Message.answer, {:prompt, Ask.StepBuilder.tts_prompt("Do you exercise?")},"<Response><Gather action=\"http://app.ask.dev/callbacks/verboice?respondent=#{respondent.id}\"><Say>Do you exercise?</Say></Gather><Gather action=\"http://app.ask.dev/callbacks/verboice?respondent=#{respondent.id}\"><Say>Do you exercise?</Say></Gather><Gather action=\"http://app.ask.dev/callbacks/verboice?respondent=#{respondent.id}\"><Say>Do you exercise?</Say></Gather></Response>"},
        {Flow.Message.answer, {:prompt, Ask.StepBuilder.audio_prompt(uuid: "foo", text: "Do you exercise?")},"<Response><Gather action=\"http://app.ask.dev/callbacks/verboice?respondent=#{respondent.id}\"><Play>http://app.ask.dev/audio/foo</Play></Gather><Gather action=\"http://app.ask.dev/callbacks/verboice?respondent=#{respondent.id}\"><Play>http://app.ask.dev/audio/foo</Play></Gather><Gather action=\"http://app.ask.dev/callbacks/verboice?respondent=#{respondent.id}\"><Play>http://app.ask.dev/audio/foo</Play></Gather></Response>"},
        {Flow.Message.answer, :end,                                                                           "<Response><Hangup/></Response>"},
        {Flow.Message.answer, {:end, {:prompt, Ask.StepBuilder.tts_prompt("Bye!")}},                          "<Response><Say>Bye!</Say><Hangup/></Response>"},
        {Flow.Message.answer, {:prompt, Ask.StepBuilder.audio_prompt(uuid: "foo", text: "Do you exercise?")}, "<Play>http://app.ask.dev/audio/foo</Play>"},
        {Flow.Message.reply("8"), {:prompt, Ask.StepBuilder.audio_prompt(uuid: "foo", text: "Do you exercise?")}, "<Play>http://app.ask.dev/audio/foo</Play>"},
      ]
    }
  end

  test "callbacks", %{conn: conn, respondent: respondent, twiml_map: twiml_map} do
    respondent_id = respondent.id

    Enum.each(twiml_map, fn
      {flow_message, step, twiml} ->
        GenServer.cast(Broker.server_ref, {:expects, fn
          {:sync_step, %Respondent{id: ^respondent_id}, ^flow_message} -> step
        end})

        digits = case flow_message do
          :answer -> nil
          {:reply, digits } -> digits
        end

        conn = VerboiceChannel.callback(conn, %{"respondent" => respondent_id, "Digits" => digits})
        assert response(conn, 200) =~ twiml
      end)
  end

  test "callback respondent not found", %{conn: conn} do
    conn = VerboiceChannel.callback(conn, %{"respondent" => 0})
    assert response(conn, 200) == "<Response><Hangup/></Response>"
  end

  test "callback without respondent", %{conn: conn} do
    conn = VerboiceChannel.callback(conn, %{})
    assert response(conn, 200) == "<Response><Hangup/></Response>"
  end
end
