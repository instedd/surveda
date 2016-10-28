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
    {:ok, conn: conn, respondent: respondent}
  end

  test "callback with :prompt", %{conn: conn, respondent: respondent} do
    respondent_id = respondent.id
    GenServer.cast(Broker.server_ref, {:expects, fn
      {:sync_step, %Respondent{id: ^respondent_id}, nil} ->
        {:prompt, "Do you exercise?"}
    end})
    conn = VerboiceChannel.callback(conn, %{"respondent" => respondent_id})
    assert response(conn, 200) =~ "<Say>Do you exercise?</Say>"
  end

  test "callback with digits", %{conn: conn, respondent: respondent} do
    respondent_id = respondent.id
    GenServer.cast(Broker.server_ref, {:expects, fn
      {:sync_step, %Respondent{id: ^respondent_id}, "8"} ->
        {:prompt, "Do you exercise?"}
    end})
    conn = VerboiceChannel.callback(conn, %{"respondent" => respondent_id, "Digits" => "8"})
    assert response(conn, 200) =~ "<Say>Do you exercise?</Say>"
  end

  test "callback with :end", %{conn: conn, respondent: respondent} do
    respondent_id = respondent.id
    GenServer.cast(Broker.server_ref, {:expects, fn
      {:sync_step, %Respondent{id: ^respondent_id}, nil} ->
        :end
    end})
    conn = VerboiceChannel.callback(conn, %{"respondent" => respondent_id})
    assert response(conn, 200) == "<Response><Hangup/></Response>"
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
