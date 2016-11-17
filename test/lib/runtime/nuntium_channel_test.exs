defmodule Ask.Runtime.NuntiumChannelTest do
  use Ask.ConnCase
  use Ask.DummySteps

  alias Ask.Respondent
  alias Ask.Runtime.{Broker, NuntiumChannel}

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
    respondent = insert(:respondent, phone_number: "123 456", sanitized_phone_number: "123456", state: "active")
    {:ok, conn: conn, respondent: respondent}
  end

  test "callback with :prompt", %{conn: conn, respondent: respondent} do
    respondent_id = respondent.id
    GenServer.cast(Broker.server_ref, {:expects, fn
      {:sync_step, %Respondent{id: ^respondent_id}, "yes"} ->
        {:prompt, "Do you exercise?"}
    end})
    conn = NuntiumChannel.callback(conn, %{"channel" => "chan1", "from" => "sms://123456", "body" => "yes"})
    assert json_response(conn, 200) == [%{"to" => "sms://123456", "body" => "Do you exercise?"}]
  end

  test "callback with :end", %{conn: conn, respondent: respondent} do
    respondent_id = respondent.id
    GenServer.cast(Broker.server_ref, {:expects, fn
      {:sync_step, %Respondent{id: ^respondent_id}, "yes"} ->
        :end
    end})
    conn = NuntiumChannel.callback(conn, %{"channel" => "chan1", "from" => "sms://123", "body" => "yes"})
    assert json_response(conn, 200) == []
  end

  test "callback respondent not found", %{conn: conn} do
    conn = NuntiumChannel.callback(conn, %{"channel" => "chan1", "from" => "sms://456", "body" => "yes"})
    assert json_response(conn, 200) == []
  end
end
