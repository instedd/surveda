defmodule Ask.Runtime.ChannelBrokerTest do
  use AskWeb.ConnCase
  use Ask.TestHelpers
  alias Ask.Runtime.{ChannelStatusServer, ChannelBroker, ChannelBrokerAgent, VerboiceChannel, NuntiumChannel}

  setup %{conn: conn} do
    {:ok, _} = ChannelStatusServer.start_link()
    {:ok, _} = ChannelBrokerAgent.start_link()
    {:ok, conn: conn}
  end

  @respondents_quantity 10

  describe "Verboice" do
    test "Every Call is made when capacity isn't set", %{} do
      channel_capacity = nil
      [test_channel, _respondents] = initialize_survey("ivr", channel_capacity)

      broker_poll()

      assert_made_calls(@respondents_quantity, test_channel)
    end

    test "Calls aren't made while the channel capacity is full", %{conn: conn} do
      channel_capacity = 5
      [test_channel, respondents] = initialize_survey("ivr", channel_capacity)

      broker_poll()
      assert_made_calls(channel_capacity, test_channel)

      callbacks = 2
      callback_n_respondents(conn, respondents, callbacks, "verboice")
      assert_made_calls(callbacks, test_channel)
    end
  end

  describe "Nuntium" do
    test "Every SMS is sent when capacity isn't set", %{} do
      channel_capacity = nil
      [test_channel, _respondents] = initialize_survey("sms", channel_capacity)

      broker_poll()

      assert_sent_smss(@respondents_quantity, test_channel)
    end

    test "SMS aren't sent while the channel capacity is full", %{conn: conn} do
      channel_capacity = 5
      [test_channel, respondents] = initialize_survey("sms", channel_capacity)

      broker_poll()
      assert_sent_smss(channel_capacity, test_channel)

      callbacks = 2
      callback_n_respondents(conn, respondents, callbacks, "nuntium")
      assert_sent_smss(callbacks, test_channel)
    end
  end

  describe "contacts_queue" do
    setup do
      mock_queued_contact = fn respondent_id, params, disposition ->
        {%{id: respondent_id, disposition: disposition}, params}
      end
      {
        :ok,
        state: %{
          contacts_queue: :pqueue.new(),
          active_contacts: Map.new(),
          channel_id: 1,
          op_count: 2
        },
        mock_queued_contact: mock_queued_contact
      }
    end

    test "queues contact", %{
      state: s,
      mock_queued_contact: mqc,
    } do
      respondent_id = 2
      params = 3
      disposition = 4
      contact = mqc.(respondent_id, params, disposition)
      size = 5

      %{contacts_queue: q} = ChannelBroker.queue_contact(s, contact, size)

      {{:value, [queud_size, queued_contact]}, _} = :pqueue.out(q)
      assert queued_contact == {%{id: respondent_id, disposition: disposition}, params}
      assert queud_size == size
    end

    test "removes the respondent", %{
      state: s,
      mock_queued_contact: mqc
    } do
      respondent_id = 2
      contact = mqc.(respondent_id, 3, 4)
      size = 5
      state = ChannelBroker.queue_contact(s, contact, size)

      %{contacts_queue: q} = ChannelBroker.remove_from_queue(state, respondent_id)

      assert :pqueue.is_empty(q)
    end


    test "doesn't removes other respondent", %{
      state: s,
      mock_queued_contact: mqc
    } do
      respondent_id = 2
      contact = mqc.(respondent_id, 3, 4)
      size = 5
      state = ChannelBroker.queue_contact(s, contact, size)

      new_state = ChannelBroker.remove_from_queue(state, 6)

      assert new_state == state
    end
  end

  defp assert_made_calls(n, test_channel) do
    for _ <- 1..n do
      assert_received [:setup, ^test_channel, _respondent, _token]
    end
    refute_received [:setup, ^test_channel, _respondent, _token]
  end

  defp assert_sent_smss(n, test_channel) do
    for _ <- 1..n do
      assert_received [:ask, ^test_channel, _respondent, _token, _reply]
    end
    refute_received [:ask, ^test_channel, _respondent, _token, _reply]
  end

  defp initialize_survey(mode, channel_capacity) do
    [_survey, _group, test_channel, respondents] =
      create_running_survey_with_channel_and_respondents_with_options(
        mode: mode,
        respondents_quantity: @respondents_quantity,
        channel_capacity: channel_capacity
      )
    [test_channel, respondents]
  end

  defp callback_n_respondents(conn, respondents, n, "nuntium" = _provider) do
    for i <- 1..n do
      NuntiumChannel.callback(conn, %{
        "path" => ["status"],
        "respondent_id" => "#{Enum.at(respondents, i).id}",
        "state" => "delivered"
      })
    end
  end

  defp callback_n_respondents(conn, respondents, n, "verboice" = _provider) do
    for i <- 1..n do
      VerboiceChannel.callback(conn, %{
        "path" => ["status", Enum.at(respondents, i).id, "token"],
        "CallStatus" => "completed",
        "CallDuration" => "15",
        "CallSid" => "1",
      })
    end
  end
end
