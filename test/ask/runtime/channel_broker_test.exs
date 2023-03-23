defmodule Ask.Runtime.ChannelBrokerTest do
  use AskWeb.ConnCase
  use Ask.TestHelpers

  alias Ask.Runtime.{
    ChannelStatusServer,
    ChannelBroker,
    ChannelBrokerAgent,
    VerboiceChannel,
    NuntiumChannel
  }

  alias Ask.{Config, Channel}

  setup %{conn: conn} do
    on_exit(fn ->
      ChannelBrokerSupervisor.terminate_children()
    end)

    {:ok, _} = ChannelStatusServer.start_link()
    {:ok, _} = ChannelBrokerAgent.start_link()
    {:ok, conn: conn}
  end

  @respondents_quantity 10

  describe "Verboice" do
    test "Every Call is made when capacity isn't set", %{} do
      channel_capacity = nil
      [test_channel, respondents, _channel] = initialize_survey("ivr", channel_capacity)

      broker_poll()

      assert_made_calls(respondents, test_channel)
    end

    test "Calls aren't made while the channel capacity is full", %{conn: conn} do
      # Arrange
      channel_capacity = 5
      [test_channel, respondents, _channel] = initialize_survey("ivr", channel_capacity)

      # Act
      broker_poll()

      # Assert
      verify_state(respondents, :active)
      assert_made_calls(Enum.take(respondents, channel_capacity), test_channel)

      # Arrange
      callbacks = 2
      release_respondents = Enum.take(respondents, callbacks)

      # Act
      callback_respondents(conn, release_respondents, "verboice")

      # Assert
      released_respondents =
        Enum.take(respondents, channel_capacity + callbacks) |> Enum.take(-callbacks)

      assert_made_calls(released_respondents, test_channel)
    end
  end

  describe "Nuntium" do
    test "Every SMS is sent when capacity isn't set", %{} do
      channel_capacity = nil
      [test_channel, respondents, _channel] = initialize_survey("sms", channel_capacity)

      broker_poll()

      assert_sent_smss(respondents, test_channel)
    end

    test "SMS aren't sent while the channel capacity is full", %{conn: conn} do
      # Arrange
      channel_capacity = 4
      [test_channel, respondents, channel] = initialize_survey("sms", channel_capacity)

      # Act
      broker_poll()

      # Assert
      verify_state(respondents, :active)
      assert_sent_smss(Enum.take(respondents, channel_capacity), test_channel)

      # Arrange
      callbacks = 4
      release_respondents = Enum.take(respondents, callbacks)

      # Act
      callback_respondents(conn, release_respondents, "nuntium", channel.id)

      # Assert
      released_respondents =
        Enum.take(respondents, channel_capacity + callbacks) |> Enum.take(-callbacks)

      assert_sent_smss(released_respondents, test_channel)
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
          op_count: 2,
          config: Config.channel_broker_config()
        },
        mock_queued_contact: mock_queued_contact
      }
    end

    test "queues contact", %{
      state: s,
      mock_queued_contact: mqc
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

  describe "on_channel_settings_change" do
    test "capacity is updated" do
      # Arrange
      first_capacity = 4
      [test_channel, respondents, _channel] = initialize_survey("sms", first_capacity)
      channel = Repo.one(Channel)
      updated_capacity = 6
      new_settings = Map.put(channel.settings, "capacity", updated_capacity)

      # Act
      ChannelBroker.on_channel_settings_change(channel.id, new_settings)
      broker_poll()

      # Assert
      assert_sent_smss(Enum.take(respondents, updated_capacity), test_channel)
    end
  end

  defp assert_made_calls(respondents, test_channel) do
    Enum.each(respondents, fn %{id: id} ->
      assert_received [:setup, ^test_channel, %{id: ^id}, _token]
    end)

    refute_received [:setup, ^test_channel, _respondent, _token]
  end

  defp assert_sent_smss(respondents, test_channel) do
    Enum.each(respondents, fn %{id: id} ->
      assert_received [:ask, ^test_channel, %{id: ^id}, _token, _reply, _channel_id]
    end)

    refute_received [:ask, ^test_channel, _respondent, _token, _reply, _channel_id]
  end

  defp initialize_survey(mode, channel_capacity) do
    [_survey, _group, test_channel, respondents, channel] =
      create_running_survey_with_channel_and_respondents_with_options(
        mode: mode,
        respondents_quantity: @respondents_quantity,
        channel_capacity: channel_capacity
      )

    [test_channel, respondents, channel]
  end

  defp callback_respondents(conn, respondents, "nuntium" = _provider, channel_id) do
    Enum.each(respondents, fn %{id: id} ->
      NuntiumChannel.callback(conn, %{
        "path" => ["status"],
        "respondent_id" => "#{id}",
        "state" => "delivered",
        "channel_id" => "#{channel_id}"
      })
    end)
  end

  defp callback_respondents(conn, respondents, "verboice" = _provider) do
    Enum.each(respondents, fn %{id: id} ->
      VerboiceChannel.callback(conn, %{
        "path" => ["status", id, "token"],
        "CallStatus" => "completed",
        "CallDuration" => "15",
        "CallSid" => "1"
      })
    end)
  end

  defp verify_state(respondents, state) do
    Enum.each(respondents, fn %{id: id} ->
      assert Repo.get(Respondent, id).state == state
    end)
  end
end
