defmodule Ask.Runtime.VerboiceChannelTest do
  use Ask.ConnCase
  use Ask.DummySteps

  alias Ask.Respondent
  alias Ask.Runtime.{Broker, VerboiceChannel}

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
        {nil, {:prompt, Ask.StepBuilder.tts_prompt("Do you exercise?")},                      "<Say>Do you exercise?</Say>"},
        {"8", {:prompt, Ask.StepBuilder.tts_prompt("Do you exercise?")},                      "<Say>Do you exercise?</Say>"},
        {nil, :end,                                                                           "<Response><Hangup/></Response>"},
        {nil, {:prompt, Ask.StepBuilder.audio_prompt(uuid: "foo", text: "Do you exercise?")}, "<Play>http://app.ask.dev/audio/foo</Play>"},
        {"8", {:prompt, Ask.StepBuilder.audio_prompt(uuid: "foo", text: "Do you exercise?")}, "<Play>http://app.ask.dev/audio/foo</Play>"},
      ]
    }
  end

  test "callbacks", %{conn: conn, respondent: respondent, twiml_map: twiml_map} do
    respondent_id = respondent.id

    Enum.each(twiml_map, fn
      {digits, step, twiml} ->
        GenServer.cast(Broker.server_ref, {:expects, fn
          {:sync_step, %Respondent{id: ^respondent_id}, ^digits} -> step
        end})

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
